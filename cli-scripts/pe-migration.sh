#!/bin/bash
# Restore databases and files to recovery PE master (assumes monolithic master); run as root
# Reference: https://docs.puppet.com/pe/latest/migrate_monolithic.html
# Uninstall PE before starting this procedure:
PUPPET_PE_VERSION=2016.4.2
/opt/puppet-enterprise-$PUPPET_PE_VERSION/puppet-enterprise-uninstaller -d -p -y
# Step 1: Back up SSL directory and databases
# run pe-mono-backup.sh on source PE master (if available) to get current files backed up
# run through pe-list-backup-files.sh and pe-download-backup-files.sh to restore files to recovery server
RESTORE_DIR=/tmp/restore
# Step 2: Restore SSL directory on new Puppet master
mkdir -p /etc/puppetlabs/puppet
tar -zxvf $RESTORE_DIR/etc_puppetlabs_puppet_ssl.tgz -C /
#Removing PE internal certs so they can be regenerated
rm -f /etc/puppetlabs/puppet/ssl/certs/pe-internal-classifier.pem
rm -f /etc/puppetlabs/puppet/ssl/certs/pe-internal-dashboard.pem
rm -f /etc/puppetlabs/puppet/ssl/private_keys/pe-internal-classifier.pem
rm -f /etc/puppetlabs/puppet/ssl/private_keys/pe-internal-dashboard.pem
rm -f /etc/puppetlabs/puppet/ssl/public_keys/pe-internal-classifier.pem
rm -f /etc/puppetlabs/puppet/ssl/public_keys/pe-internal-dashboard.pem
rm -f /etc/puppetlabs/puppet/ssl/ca/signed/pe-internal-classifier.pem
rm -f /etc/puppetlabs/puppet/ssl/ca/signed/pe-internal-dashboard.pem
# Step 3: Install PE
$PE_CERTNAME=<fqdn_of_recovery_server>
$ALIASES="<list of puppet aliases>"
# create pe.conf file
cat > /opt/pe.conf << CONF
"console_admin_password": "password"
"puppet_enterprise::puppet_master_host": "$PE_CERTNAME"
"pe_install::puppet_master_dnsaltnames": ["$ALIASES"]
CONF
/opt/puppet-enterprise-$PUPPET_PE_VERSION/puppet-enterprise-installer -c /opt/pe.conf
/opt/puppetlabs/bin/puppet agent -t
# Step 4: restore PE databases
RESTORE_DIR=/tmp/restore
puppet resource service puppet ensure=stopped
puppet resource service pe-puppetserver ensure=stopped
puppet resource service pe-puppetdb ensure=stopped
puppet resource service pe-console-services ensure=stopped
puppet resource service pe-nginx ensure=stopped
puppet resource service pe-activemq ensure=stopped
puppet resource service pe-orchestration-services ensure=stopped
puppet resource service pxp-agent ensure=stopped
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc $RESTORE_DIR/pe-puppetdb.backup.bin -d template1
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc $RESTORE_DIR/pe-classifier.backup.bin -d template1
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc $RESTORE_DIR/pe-activity.backup.bin -d template1
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc $RESTORE_DIR/pe-rbac.backup.bin -d template1
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc $RESTORE_DIR/pe-orchestration.backup.bin -d template1
#Start PE services
#Install database extensions and repair database permissions
#Repair PE classification groups to reflect the 2016.4.x Puppet master’s certificate name.
puppet enterprise configure
#You can safely ignore the following errors:
#pg_restore: [archiver (db)] Error while PROCESSING TOC:
#pg_restore: [archiver (db)] Error from TOC entry 5; 2615 2200 SCHEMA public pe-postgres
#pg_restore: [archiver (db)] could not execute query: ERROR:  schema "public" already exists
#Command was: CREATE SCHEMA public;
# Step 5: remove old Puppet master cert (if recovery server has a new name)
OLD_MASTER_CERTNAME=<3.8_PUPPET_MASTER_CERTNAME>
puppet node deactivate $OLD_MASTER_CERTNAME
puppet cert clean $OLD_MASTER_CERTNAME
# Step 6: Migrate your data
# Follow instructions at: https://docs.puppet.com/pe/latest/migrate_monolithic.html#step-6-migrate-your-data
# Assume git SSH key is /root/.ssh/id_rsa
# Initial r10k configuration/code sync
mv /etc/puppetlabs/puppet/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml.example
cat > /etc/puppetlabs/r10k/r10k.yaml << R10KYAML
---
cachedir: '/opt/puppetlabs/server/data/r10k'
sources:
  puppet:
    basedir: '/etc/puppetlabs/code/environments'
    prefix: false
    remote: '<control_repo_clone_url>'
git:
  provider: 'rugged'
  private_key: '/root/.ssh/id_rsa'
  username: 'git'
forge:
  proxy: 'http://proxy.mycompany.com:8080'
R10KYAML
r10k deploy environment production -pv
# Reconfigure PE console cerficicate: https://docs.puppet.com/pe/latest/custom_console_cert.html
# If hostname is changing, get a new certificate
# Step 7: Configure your Puppet agents to point at the new Puppet master
puppet resource service pe-puppetserver ensure=running
puppet resource service pe-orchestration-services ensure=running
puppet resource service pe-nginx ensure=running
puppet resource service pe-postgresql ensure=stopped
puppet resource service pe-postgresql ensure=running
puppet resource service pe-puppetdb ensure=running
puppet resource service pe-console-services ensure=running
puppet resource service puppet ensure=running
puppet agent -t
