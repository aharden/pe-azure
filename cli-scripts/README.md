# azure/cli-scripts

[How to install the MS Azure CLI](https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/)

## cli-del-vhds.sh

Given an Azure storage account and access key, remove all VHD files from the `vhds`
container that are in an input list.

## cli-del-vnics.sh

Given an Azure subscription and Resource Group, remove all Network Interface objects
from the resource group that are in an input list.

## cli-install-apt.sh

Installs the Azure CLI on Debian/Ubuntu using apt to install Node.js and using npm to install azure-cli.

## pe-mono-backup.sh

Backs up PE deployment unique data to specified Azure storage account.

## How to recover PE backup files to recovery server

1. Choose desired day of week to restore to: [sun,mon,tue,wed,thu,fri,sat]
1. Go to Azure storage account for these backups and find the container for desired deployment and day
1. Install Azure CLI to recovery PE server: ex: `./cli-install-apt.sh`
1. List blob files in desired backup container: ex: `./pe-list-backup-files.sh`
1. Download listed blob files to recovery PE server and extract: ex: `./pe-download-backup-files.sh`

## How to restore PE server

Follow PE recovery procedure: ex: `./pe-restore.sh`

## How to migrate to a new PE server

Follow PE migration procedure: ex: `./pe-migration.sh`
