# Puppet Enterprise Azure Resource Manager Templates

These templates deploy Ubuntu 16.04 LTS servers configured to run Puppet
Enterprise.

## `monolith`

This template uses the `containers/custom/ubuntu_puppet.sh` custom script to prepare a server to
run a monolithic installation of Puppet Enterprise.  This server is the root
of a Puppet Enterprise deployment, running the Certificate Authority,
PuppetDB, PE Console, and PE Master roles.

## `compile_master`

This template uses the `containers/custom/ubuntu_compile.sh` custom script to prepare three or more
servers to join a monolithic installation of Puppet Enterprise as compile masters.
The template includes a load balancer whose desired private IP address must be provided.
The Puppet Enterprise deployment's CA/Master needs to be specified by IP address as opposed to by name.
