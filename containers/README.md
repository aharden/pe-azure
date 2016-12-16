# Azure Storage Account Containers for Puppet Enterprise

Stage these blob containers in the `customscript` storage account specified in
your Puppet Enterprise ARM template to support the configurations provided by
the custom script.  Set them to Access Type `Blob` to support anonymous
downloads.

## custom

This container holds the custom scripts used by the PE templates.

### `ubuntu_puppet.sh`

Prepares an Ubuntu 16.04 LTS server with two data disks to run Puppet
Enterprise.  Used by the `monolith` template.

### `ubuntu_compile.sh`

Prepares an Ubuntu 16.04 LTS server with one data disk to join a Puppet
Enterprise deployment as a compile master.  Used by the `compile_master`
template.

## puppet

This container holds the Puppet Enterprise tarballs for Ubuntu 16.04 LTS that
the custom script will download.  You must stage the version(s) specified in
the `puppet_pe_version` parameter of the templates.  The PE tarballs can be
downloaded here: https://puppet.com/download-puppet-enterprise.
