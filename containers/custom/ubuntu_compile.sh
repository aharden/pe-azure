#!/bin/bash
PUPPET_MASTER=$1
PROXY=$2
PROVIDER=$3
PLATFORM=$4
DOMAIN=$5
ALIASES=$6
STORAGE_ACCT=$7
CENTRIFY_ZONE=$8
SHORT_HOSTNAME=$(hostname)
PE_CERTNAME=$SHORT_HOSTNAME.$DOMAIN

# Reference: http://unix.stackexchange.com/questions/119269/how-to-get-ip-address-using-shell-script
IP_ADDRESS=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
# Reverse IP recipe from http://ubuntuforums.org/showthread.php?t=1554177
REVERSE_IP=$(echo $IP_ADDRESS|awk -F"." '{for(i=NF;i>0;i--) printf i!=1?$i".":"%s",$i}')

# create txt file with script parameters
echo "$PUPPET_MASTER $PROXY $PROVIDER $PLATFORM $DOMAIN $ALIASES $STORAGE_ACCT $CENTRIFY_ZONE" >> /etc/customscr.txt

# set hosts file
echo "127.0.0.1 $PE_CERTNAME $SHORT_HOSTNAME localhost" >/etc/hosts

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
search $DOMAIN tycoelectronics.net tycoelectronics.com ohs.tycoelectronics.com us.tycoelectronics.com
nameserver 135.107.26.202
nameserver 135.107.90.202
ETHCONF
# generate new /etc/resolv.conf
/sbin/resolvconf -u
# inject domain search settings into permanent config
cat >> /etc/network/interfaces.d/50-cloud-init.cfg << CFG
    dns-search $DOMAIN tycoelectronics.net tycoelectronics.com ohs.tycoelectronics.com us.tycoelectronics.com
CFG

# these are all the OIDs that we may map or already have
# https://docs.puppetlabs.com/puppet/latest/reference/ssl_attributes_extensions.html

# create puppet trusted facts
if [ ! -d /etc/puppetlabs/puppet ]; then
  mkdir -p /etc/puppetlabs/puppet
fi

  cat > /etc/puppetlabs/puppet/csr_attributes.yaml << YAML
extension_requests:
  1.3.6.1.4.1.34380.1.1.8: 'Puppet Enterprise'
  1.3.6.1.4.1.34380.1.1.13: 'roles::puppet::master'
  1.3.6.1.4.1.34380.1.1.17: $PROVIDER
  1.3.6.1.4.1.34380.1.1.23: $PLATFORM
  1.3.6.1.4.1.34380.1.1.25: $SHORT_HOSTNAME
YAML

# Build file system
mkfs -t ext4 /dev/sdc

#mount /dev/sdc as new /opt
mount /dev/sdc /opt

#update fstab file to mount EBS on system startup
echo "/dev/sdc /opt ext4 noatime 0 0" >> /etc/fstab

# create puppet custom fact
mkdir -p /etc/puppetlabs/facter/facts.d
cat <<FACT > /etc/puppetlabs/facter/facts.d/centrify_zone.yaml
---
centrify_zone: '$CENTRIFY_ZONE'
FACT

# Install PE compile master:
# https://docs.puppet.com/pe/2016.4/install_multimaster.html#install-a-compile-master
/usr/bin/curl -k https://$PUPPET_MASTER:8140/packages/current/install.bash | sudo bash -s main:dns_alt_names=$ALIASES

# Use Puppet CA to sign cert: puppet cert --allow-dns-alt-names sign $PE_CERTNAME
# - Can't be automated via CA API as of PE 2016.4.2 for security reasons
# Run Agent: /opt/puppetlabs/bin/puppet agent -t
# - Can't run agent until certificate request is signed
# Use PE Node Classifier to join server to PE Master node group
# Run Agent again to pick up PE Master configuration: /opt/puppetlabs/bin/puppet agent -t

# inject TE HTTP proxy
cat > /root/.curlrc << CURLRC
proxy=$PROXY
noproxy=169.254.169.254,localhost,tycoelectronics.com,tycoelectronics.net,127.0.0.1
CURLRC
