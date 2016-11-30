#!/bin/bash
# install Azure CLI on Debian/Ubuntu
# comment out the PROXY lines if you don't need them
PROXY=http://proxy.mycompany.com:8080
apt update
apt install npm -y
npm config set proxy $PROXY
npm config set https-proxy $PROXY
npm install -g azure-cli
ln -s /usr/bin/nodejs /usr/bin/node
