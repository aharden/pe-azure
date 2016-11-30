#!/bin/bash
# List backup files in specified container
# Arguments:
# $1: Azure storage account blob name (ex: myazurestorageaccount)
# $2: Azure storage account access key
# $3: Puppet Enterprise backup container in "deployment-day" format"
STORAGE_ACCOUNT_NAME_DEFAULT=myazurestorageaccount
STORAGE_ACCOUNT_KEY_DEFAULT=myReallyLongAzureStorageAccountAccessKey
CONTAINER_DEFAULT=puppet-mon
STORAGE_ACCOUNT_NAME=${1:-$STORAGE_ACCOUNT_NAME_DEFAULT}
STORAGE_ACCOUNT_KEY=${2:-$STORAGE_ACCOUNT_KEY_DEFAULT}
CONTAINER=${3:-$CONTAINER_DEFAULT}
# comment out the PROXY lines if you don't need them
PROXY=http://proxy.mycompany.com:8080
# Setup
# all of these required for Azure CLI to work through Proxy
export HTTP_PROXY=$PROXY
export HTTPS_PROXY=$PROXY
export http_proxy=$PROXY
export https_proxy=$PROXY
export AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT_NAME
export AZURE_STORAGE_ACCESS_KEY=$STORAGE_ACCOUNT_KEY
azure storage blob list $CONTAINER
