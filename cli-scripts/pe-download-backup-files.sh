#!/bin/bash
# Download backup files from specified container
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
RESTORE_DIR=/tmp/restore
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
if [ ! -d $RESTORE_DIR ]; then
  mkdir -p $RESTORE_DIR
fi
# download the archived files to restore directory
SOURCE_DIRS="/etc/puppetlabs /etc/puppetlabs/puppet/ssl /opt/puppetlabs/server/data/console-services/certs /opt/puppetlabs/server/data/postgresql/9.4/data/certs"
PE_DATABASES="pe-puppetdb pe-classifier pe-rbac pe-activity pe-orchestrator"
for DIRECTORY in $SOURCE_DIRS
do
  ARCHIVE_NAME=`echo ${DIRECTORY} | sed s/^\\\/// | sed s/\\\//_/g`
  azure storage blob download --container $CONTAINER -b <blob_file_name>.tgz $RESTORE_DIR -q
done
# run the following command for each .tgz file to extract to $RESTORE_DIR
# tar zxvf $RESTORE_DIR/<blob_file_name>.tgz -C $RESTORE_DIR
for DATABASE in $PE_DATABASES
do
  azure storage blob download --container $CONTAINER -b $DATABASE.backup.bin $RESTORE_DIR -q
done
