#!/bin/bash
# delete all Network Interfaces (vNICs) listed in vnics.in
# requires Azure CLI and active Azure login session
# generate master list of all vNICs and edit as required before running this script:
# azure network nic list -s $AZURE_SUBSCRIPTION -g $AZURE_RESOURCE_GROUP --json | jq -r '.[] | .name' > vnics.in
AZURE_SUBSCRIPTION=MyAzureSubscription
AZURE_RESOURCE_GROUP=MyAzureResourceGroup
while read line; do
        azure network nic delete -q -s $AZURE_SUBSCRIPTION -g $AZURE_RESOURCE_GROUP $line
done < vnics.in
