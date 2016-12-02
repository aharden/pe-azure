#!/bin/bash
# Script to set up Code Manager deployment user on PE 2016.4
# https://docs.puppet.com/pe/latest/code_mgr_config.html#set-up-authentication-for-code-manager
# Commands to be run as root from PE master console
[[ $EUID -eq 0 ]] || { echo "${0##*/} must be run as root or with sudo" >&2; exit 1; }

# Environment variables
CERT="$(puppet agent --configprint hostcert)"
KEY="$(puppet agent --configprint hostprivkey)"
CACERT="$(puppet agent --configprint localcacert)"
SERVER="$(puppet agent --configprint server)"

# Use Puppet's curl
alias curl='/opt/puppetlabs/puppet/bin/curl'

# Install jq
puppet resource package jq ensure=installed

# Make a root .puppetlabs directory for token
mkdir /root/.puppetlabs

# Create deployment user
curl -k -X POST https://localhost:4433/rbac-api/v1/users \
    --cert $CERT --key $KEY --cacert $CACERT \
    -H "Content-Type: application/json" \
    -d '{"login":"deployment", "email":"puppet@te.com", "display_name":"Code Manager Service Account", "role_ids": [4], "password":"puppetlabs"}'

# Request an authentication token and store in /root/.puppetlabs/token 
curl -k -X POST https://localhost:4433/rbac-api/v1/auth/token \
    --cert $CERT --key $KEY --cacert $CACERT \
    -H "Content-Type: application/json" \
    -d '{"login":"deployment", "password":"puppetlabs", "lifetime":"10y", "label":"PE Master token"}' | \
    jq -r '.token' > /root/.puppetlabs/token

# Deploy all environments:
puppet code deploy --all --wait

# Additional functions:
# View available roles:
#curl -k -X GET https://localhost:4433/rbac-api/v1/roles \
#    --cert $CERT --key $KEY --cacert $CACERT \
#    -H "Content-Type: application/json" | jq
# "Code Deployers" is role id 4 in PE 2016.4
# Revoke an authentication token:
#curl -k -X DELETE https://localhost:4433/rbac-api/v2/tokens \
#    --cert $CERT --key $KEY --cacert $CACERT \
#    -H "Content-Type: application/json" \
#    -d '{"revoke_tokens_by_labels":["PE Master token"]}'
