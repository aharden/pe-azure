#!/bin/bash
# Restore databases and files to recovery PE install (assumes monolithic master); run as root
# Reference: https://docs.puppet.com/pe/latest/maintain_backup_restore.html#restore-your-database-and-puppet-enterprise-files
# Recovery server must have same certname and DNS aliases configured as old server for recovery PE install
RESTORE_DIR=/tmp/restore
# Step 2: Stop PE services
puppet resource service puppet ensure=stopped
puppet resource service pe-puppetserver ensure=stopped
puppet resource service pe-orchestration-services ensure=stopped
puppet resource service pe-nginx ensure=stopped
puppet resource service pe-puppetdb ensure=stopped
puppet resource service pe-console-services ensure=stopped
# Step 3: restore PE PostgreSQL DBs from individual backups:
# Step 3 pt 1: https://docs.puppet.com/pe/latest/maintain_console-db.html#restore-individual-database-backup
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc -d template1 $RESTORE_DIR/pe-puppetdb.backup.bin
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc -d template1 $RESTORE_DIR/pe-classifier.backup.bin
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc -d template1 $RESTORE_DIR/pe-activity.backup.bin
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc -d template1 $RESTORE_DIR/pe-rbac.backup.bin
sudo -u pe-postgres /opt/puppetlabs/server/bin/pg_restore -Cc -d template1 $RESTORE_DIR/pe-orchestration.backup.bin
# Step 3 pt 2: https://docs.puppet.com/pe/latest/maintain_console-db.html#fixing-database-ownership
# Use `access.sql` located in this directory
sudo -u pe-postgres -s /bin/bash -c '/opt/puppetlabs/server/bin/psql < ./access.sql'
# Step 4: restore PE directories and files
/bin/cp -rf $RESTORE_DIR/etc/puppetlabs/puppet/puppet.conf /etc/puppetlabs/puppet/puppet.conf
rm -rf /etc/puppetlabs/puppet/ssl
/bin/cp -rf $RESTORE_DIR/etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/
rm -rf /etc/puppetlabs/puppetdb/ssl
/bin/cp -rf $RESTORE_DIR/etc/puppetlabs/puppetdb/ssl /etc/puppetlabs/puppetdb/
/bin/cp -rf $RESTORE_DIR/opt/puppetlabs/server/data/postgresql/9.4/data/certs/* /opt/puppetlabs/server/data/postgresql/9.4/data/certs/
/bin/cp -rf $RESTORE_DIR/opt/puppetlabs/server/data/console-services/certs/* /opt/puppetlabs/server/data/console-services/certs/
# Step 5: remove cached catalog from Puppet master
rm -f /opt/puppetlabs/puppet/cache/client_data/catalog/<CERTNAME>.json
# Step 6: change ownership of the restored files
chown pe-puppet:pe-puppet /etc/puppetlabs/puppet/puppet.conf
chown -R pe-puppet:pe-puppet /etc/puppetlabs/puppet/ssl/
chown -R pe-console-services /opt/puppetlabs/server/data/console-services/certs/
chown -R pe-postgres:pe-postgres /opt/puppetlabs/server/data/postgresql/9.4/data/certs/
chown -R pe-puppetdb:pe-puppetdb /etc/puppetlabs/puppetdb/ssl/
# Step 7: restart PE services
puppet resource service pe-puppetserver ensure=running
puppet resource service pe-orchestration-services ensure=running
puppet resource service pe-nginx ensure=running
puppet resource service pe-postgresql ensure=stopped
puppet resource service pe-postgresql ensure=running
puppet resource service pe-puppetdb ensure=running
puppet resource service pe-console-services ensure=running
puppet resource service puppet ensure=running
# Step 8: Restore modules, manifests, hieradata, and, if necessary, Code Manager SSH keys.
# These are typically located in the /etc/puppetlabs/ directory, but you may have configured them in another location.
