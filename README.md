# pe_azure

Resources for deploying Puppet Enterprise on Microsoft Azure Ubuntu Linux VMs

## `cli-scripts`

Scripts that do useful things like install the Azure CLI, perform PE backups,
and assist with PE restores and migrations.

## `containers`

Azure Storage Account containers that should be staged to allow the provided
Resource Manager templates to work.

## `templates`

Azure Resource Manager templates deploying Ubuntu Linux Server VMs with Puppet
Enterprise

### `monolith`

Deploys a PE monolithic master to an established Azure VPC.

### `compile_master`

Deploys a group of PE compile masters along with a load balancer that can be
attached to an existing PE monolithic master to scale a deployment.
