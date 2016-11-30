#!/bin/bash
# delete all VHD blobs from vhds container listed in vhds.in
# requires Azure CLI and jq
# generate master list of all VHD blobs and edit as required before running this script:
# azure storage blob list vhds --json | jq -r '.[] | .name' > vhds.in
STORAGE_ACCOUNT_NAME=myazurestorageaccount
STORAGE_ACCOUNT_KEY=myReallyLongAzureStorageAccountAccessKey
export AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT_NAME
export AZURE_STORAGE_ACCESS_KEY=$STORAGE_ACCOUNT_KEY
while read line; do
        azure storage blob delete -q --container vhds $line
done < vhds.in
