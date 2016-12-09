#!/bin/bash
# Given a list of Puppet Enterprise compile master certnames, pin them to the
#  PE Masters Node Group
# Must be run on PE CA/MoM as root; can be done before compile masters are
#  joined to deployment
# input list: ./masters.in

# ensure jq is installed
puppet resource package jq ensure=installed

# Environment variables
CERT="$(puppet agent --configprint hostcert)"
KEY="$(puppet agent --configprint hostprivkey)"
CACERT="$(puppet agent --configprint localcacert)"

# Use Puppet's curl
alias curl='/opt/puppetlabs/puppet/bin/curl'

# Get the node group ID of "PE Masters"
GROUP=$(curl -k -X GET https://localhost:4433/classifier-api/v1/groups \
    --cert $CERT --key $KEY --cacert $CACERT | \
    jq -r '.[] | select(.name=="PE Master") | .id')

# Pin the nodes in the passed list into the group
while read master; do
  curl -k -X POST https://localhost:4433/classifier-api/v1/groups/${GROUP}/pin \
    --cert $CERT --key $KEY --cacert $CACERT \
    -H "Content-Type: application/json" \
    -d "{\"nodes\":[\"${master}\"]}"
done < ./masters.in
