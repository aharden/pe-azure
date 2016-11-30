#!/bin/bash
# Backup of Puppet Enterprise unique items to designated Azure storage account container
# Should be run once daily; built-in backup retention of one week
# Prerequisite: Azure CLI must be installed
# PE Backup/Restore Reference: https://docs.puppet.com/pe/latest/maintain_backup_restore.html
# PE Migration Reference: https://docs.puppet.com/pe/latest/migrate_monolithic.html
# Reference: https://blog.sleeplessbeastie.eu/2013/03/12/simple-shell-script-to-backup-selected-directories/
# Reference: http://stackoverflow.com/questions/2013547/assigning-default-values-to-shell-variables-with-a-single-command-in-bash
# Arguments:
# $1: Azure storage account blob name (ex: myazurestorageaccount)
# $2: Azure storage account access key
# $3: Puppet Enterprise Deployment name (used in container label along with day)
STORAGE_ACCOUNT_NAME_DEFAULT=myazurestorageaccount
STORAGE_ACCOUNT_KEY_DEFAULT=myReallyLongAzureStorageAccountAccessKey
DEPLOYMENT_DEFAULT=puppet
STORAGE_ACCOUNT_NAME=${1:-$STORAGE_ACCOUNT_NAME_DEFAULT}
STORAGE_ACCOUNT_KEY=${2:-$STORAGE_ACCOUNT_KEY_DEFAULT}
DEPLOYMENT=${3:-$DEPLOYMENT_DEFAULT}
BACKUP_DIR=/tmp/backup
DB_BACKUP_DIR=/tmp/db_backup
SOURCE_DIRS="/etc/puppetlabs /etc/puppetlabs/puppet/ssl /opt/puppetlabs/server/data/console-services/certs /opt/puppetlabs/server/data/postgresql/9.4/data/certs"
PE_DATABASES="pe-puppetdb pe-classifier pe-rbac pe-activity pe-orchestrator"
# comment out the PROXY lines if you don't need them
PROXY=http://proxy.mycompany.com:8080
# all of these required for Azure CLI to work through Proxy
export HTTP_PROXY=$PROXY
export HTTPS_PROXY=$PROXY
export http_proxy=$PROXY
export https_proxy=$PROXY
export AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT_NAME
export AZURE_STORAGE_ACCESS_KEY=$STORAGE_ACCOUNT_KEY
DAY=`date +%a |tr A-Z a-z`
CONTAINER=$DEPLOYMENT-$DAY
# wipe existing container for this deployment and day
azure storage container delete $CONTAINER -q
# create new container for this deployment and day
# create will fail until old container is fully deleted
until azure storage container create $CONTAINER
do
  sleep 5s
done
if [ ! -d $BACKUP_DIR ]; then
  mkdir -p $BACKUP_DIR
fi
for DIRECTORY in $SOURCE_DIRS
do
  ARCHIVE_NAME=`echo ${DIRECTORY} | sed s/^\\\/// | sed s/\\\//_/g`
  tar pcfzP ${BACKUP_DIR}/${ARCHIVE_NAME}.tgz ${DIRECTORY} 2>&1 | tee > ${BACKUP_DIR}/${ARCHIVE_NAME}.log
  azure storage blob upload -f $BACKUP_DIR/$ARCHIVE_NAME.tgz --container $CONTAINER -b $ARCHIVE_NAME.tgz -q
done
if [ ! -d $DB_BACKUP_DIR ]; then
  mkdir -p $DB_BACKUP_DIR
  chown pe-postgres:pe-postgres $DB_BACKUP_DIR
fi
# individual DB backups per PE Migration instructions
for DATABASE in $PE_DATABASES
do
  sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_dump -Fc $DATABASE -f $DB_BACKUP_DIR/$DATABASE.backup.bin
  azure storage blob upload -f $DB_BACKUP_DIR/$DATABASE.backup.bin --container $CONTAINER -b $DATABASE.backup.bin -q
done
