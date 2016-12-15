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
PUPPET_PE_CODEMGRPWD=${12}

# Reference: http://unix.stackexchange.com/questions/119269/how-to-get-ip-address-using-shell-script
IP_ADDRESS=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
# Reverse IP recipe from http://ubuntuforums.org/showthread.php?t=1554177
REVERSE_IP=$(echo $IP_ADDRESS|awk -F"." '{for(i=NF;i>0;i--) printf i!=1?$i".":"%s",$i}')

# create txt file with script parameters
echo "$UBUNTU_VERSION $PUPPET_PE_VERSION $PUPPET_PE_CONSOLEPWD $PROXY $SHORT_HOSTNAME $PROVIDER $PLATFORM $DOMAIN $PE_CERTNAME $ALIASES $STORAGE_ACCT $PUPPET_PE_CODEMGRPWD" >> /etc/customscr.txt

# set hosts file
echo "127.0.0.1 $PE_CERTNAME $SHORT_HOSTNAME localhost $ALIASES" >/etc/hosts

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

# create pe.conf file - uncomment/customize Code Manager settings if required
cat > /opt/pe.conf << CONF
"console_admin_password": "$PUPPET_PE_CONSOLEPWD"
"puppet_enterprise::puppet_master_host": "$PE_CERTNAME"
"pe_install::puppet_master_dnsaltnames": ["puppet"]
#"puppet_enterprise::profile::master::r10k_remote": "<control repo git clone URL>"
#"puppet_enterprise::profile::master::r10k_private_key": "/etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa"
#"puppet_enterprise::profile::master::code_manager_auto_configure": true
CONF

# download PE install sources
mkdir -p /opt/puppet-enterprise-$PUPPET_PE_VERSION
curl -L -s -o /opt/pe-$PUPPET_PE_VERSION-installer.tar.gz "https://$STORAGE_ACCT.blob.core.windows.net/puppet/puppet-enterprise-$PUPPET_PE_VERSION-ubuntu-$UBUNTU_VERSION-amd64.tar.gz"
#Drop installer in predictable location
tar --extract --file=/opt/pe-$PUPPET_PE_VERSION-installer.tar.gz --strip-components=1 --directory=/opt/puppet-enterprise-$PUPPET_PE_VERSION
/opt/puppet-enterprise-$PUPPET_PE_VERSION/puppet-enterprise-installer -c /opt/pe.conf
echo "*" > /etc/puppetlabs/puppet/autosign.conf

/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --color=false --verbose

# Remove PE package source after install
rm /etc/apt/sources.list.d/*

# Install Azure CLI
/opt/puppetlabs/bin/puppet resource package npm ensure=installed
/opt/puppetlabs/bin/puppet resource package nodejs-legacy ensure=installed
npm config set proxy $PROXY
npm config set https-proxy $PROXY
npm install -g azure-cli

# Set up Code Manager deployment user on PE 2016.4
# https://docs.puppet.com/pe/latest/code_mgr_config.html#set-up-authentication-for-code-manager
CERT="$(puppet agent --configprint hostcert)"
KEY="$(puppet agent --configprint hostprivkey)"
CACERT="$(puppet agent --configprint localcacert)"
SERVER="$(puppet agent --configprint server)"
alias curl='/opt/puppetlabs/puppet/bin/curl'

# Install jq
/opt/puppetlabs/bin/puppet resource package jq ensure=installed

# Make a root .puppetlabs directory for Code Manager deployment user token
mkdir /root/.puppetlabs

# Create deployment user
curl -k -X POST https://localhost:4433/rbac-api/v1/users \
    --cert $CERT --key $KEY --cacert $CACERT \
    -H "Content-Type: application/json" \
    -d '{"login":"deployment", "email":"puppet@te.com", "display_name":"Code Manager Service Account", "role_ids": [4], "password":"$PUPPET_PE_CODEMGRPWD"}'

# Request an authentication token and store in /root/.puppetlabs/token
curl -k -X POST https://localhost:4433/rbac-api/v1/auth/token \
    --cert $CERT --key $KEY --cacert $CACERT \
    -H "Content-Type: application/json" \
    -d '{"login":"deployment", "password":"$PUPPET_PE_CODEMGRPWD", "lifetime":"10y", "label":"PE Master token"}' | \
    jq -r '.token' > /root/.puppetlabs/token

# Before first code deployment, create and place /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa
