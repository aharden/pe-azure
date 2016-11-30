#!/bin/bash
UBUNTU_VERSION=$1
PUPPET_PE_VERSION=$2
PUPPET_PE_CONSOLEPWD=$3
PROXY=$4
SHORT_HOSTNAME=$5
PROVIDER=$6
PLATFORM=$7
DOMAIN=$8
PE_CERTNAME=$9
ALIASES=${10}
STORAGE_ACCT=${11}

# Reference: http://unix.stackexchange.com/questions/119269/how-to-get-ip-address-using-shell-script
IP_ADDRESS=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
# Reverse IP recipe from http://ubuntuforums.org/showthread.php?t=1554177
REVERSE_IP=$(echo $IP_ADDRESS|awk -F"." '{for(i=NF;i>0;i--) printf i!=1?$i".":"%s",$i}')

# create txt file with script parameters
echo "$UBUNTU_VERSION $PUPPET_PE_VERSION $PUPPET_PE_CONSOLEPWD $PROXY $SHORT_HOSTNAME $PROVIDER $PLATFORM $DOMAIN $PE_CERTNAME $ALIASES $STORAGE_ACCT" >> /etc/customscr.txt

# set hosts file
echo "127.0.0.1 localhost $SHORT_HOSTNAME $ALIASES" >/etc/hosts

# Set DNS
echo "
update delete $PE_CERTNAME A
send
update delete $REVERSE_IP.in-addr.arpa PTR
send
update add $PE_CERTNAME 86400 A $IP_ADDRESS
send
update add $REVERSE_IP.in-addr.arpa 14400 PTR $PE_CERTNAME.
send" | nsupdate

# inject domain search settings for current run
cat > /run/resolvconf/interface/eth0.inet << ETHCONF
search $DOMAIN mydomain.com myotherdomain.com
ETHCONF
# generate new /etc/resolv.conf
/sbin/resolvconf -u
# inject domain search settings into permanent config
cat >> /etc/network/interfaces.d/50-cloud-init.cfg << CFG
    dns-search $DOMAIN mydomain.com myotherdomain.com
CFG

# inject HTTP proxy
cat > /root/.curlrc << CURLRC
proxy=$PROXY
noproxy=169.254.169.254,localhost,mydomain.com,myotherdomain.com,127.0.0.1
CURLRC

# these are all the OIDs that we may map or already have
# https://docs.puppetlabs.com/puppet/latest/reference/ssl_attributes_extensions.html

# create puppet trusted facts
if [ ! -d /etc/puppetlabs/puppet ]; then
  mkdir -p /etc/puppetlabs/puppet
fi

  cat > /etc/puppetlabs/puppet/csr_attributes.yaml << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.1.8: 'Puppet Enterprise'
  1.3.6.1.4.1.34380.1.1.17: $PROVIDER
  1.3.6.1.4.1.34380.1.1.23: $PLATFORM
  1.3.6.1.4.1.34380.1.1.25: $SHORT_HOSTNAME
YAML

# Build file system
mkfs -t ext4 /dev/sdc
mkfs -t ext4 /dev/sdd

#copy original /var to /dev/xvdf
mkdir /mnt/new
mount /dev/sdd /mnt/new
cd /var
cp -ax * /mnt/new
cd /
mv var var.old

#mount /dev/sdc as new /opt
mount /dev/sdc /opt

#mount /dev/sdd as new /var
mkdir /var
mount /dev/sdd /var

#update fstab file to mount EBS on system startup
echo "/dev/sdc /opt ext4 noatime 0 0" >> /etc/fstab
echo "/dev/sdd /var ext4 noatime 0 0" >> /etc/fstab

# create pe.conf file
cat > /opt/pe.conf << CONF
"console_admin_password": "$PUPPET_PE_CONSOLEPWD"
"puppet_enterprise::puppet_master_host": "$PE_CERTNAME"
"pe_install::puppet_master_dnsaltnames": ["puppet"]
CONF

# download PE install sources
mkdir -p /opt/puppet-enterprise-$PUPPET_PE_VERSION
curl -L -s -o /opt/pe-$PUPPET_PE_VERSION-installer.tar.gz "https://$STORAGE_ACCT.blob.core.windows.net/puppet/puppet-enterprise-$PUPPET_PE_VERSION-ubuntu-$UBUNTU_VERSION-amd64.tar.gz"
#Drop installer in predictable location
tar --extract --file=/opt/pe-$PUPPET_PE_VERSION-installer.tar.gz --strip-components=1 --directory=/opt/puppet-enterprise-$PUPPET_PE_VERSION
/opt/puppet-enterprise-$PUPPET_PE_VERSION/puppet-enterprise-installer -c /opt/pe.conf
echo "*" > /etc/puppetlabs/puppet/autosign.conf

/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --color=false --verbose

# Install Azure CLI
apt install npm nodejs-legacy -y
npm config set proxy $PROXY
npm config set https-proxy $PROXY
npm install -g azure-cli

# Install updates
apt update
apt upgrade -y
