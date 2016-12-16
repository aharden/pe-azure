# Puppet Enterprise Azure Resource Manager Templates

These templates deploy Ubuntu 16.04 LTS servers configured to run Puppet
Enterprise.

## `monolith`

This template uses the `ubuntu_puppet.sh` custom script to prepare a server to
run a monolithic installation of Puppet Enterprise.  This server is the root
of a Puppet Enterprise deployment, running the Certificate Authority,
PuppetDB, PE Console, and PE Master roles.

| Parameter Name | Type | Default |                                   
|----------------|------|---------|
|virtualMachineName          | String       | puppet |
|adminUserName               | String       | puppet |
|adminPassword               | SecureString | Puppet!Puppet |
|operatingSystemType         | String       | linux |
|virtualMachineSize          | String       | Standard_DS2_v2 |
|publisher                   | String       | Canonical |
|offer                       | String       | UbuntuServer |
|sku                         | String       | 16.04.0-LTS |
|storageAccountName          | String       | none (provide storage account for base VM disk) |
|diskStorageAccountName      | String       | none (provide storage account for VM data disks) |
|datadisk1size               | Int          | 20 (GB; used for /opt volume) |
|datadisk2size               | Int          | 10 (GB; used for /var volume) |
|virtualNetworkName          | String       | none (provide existing virtual network name) |
|virtualNetworkResourceGroup | String       | none (provide the RG name where the virtual network is) |
|subnetName                  | String       | none (provide existing subnet from the virtual network) |
|customscriptName            | String       | ubuntu_puppet.sh |
|customscriptStorageAccount  | String       | none (provide storage account for custom script container) |
|diagnosticsStorageAccount   | String       | none (provide storage account for diagnostics data) |
|domain                      | String       | none (provide DNS domain name for server) |
|ubuntu_version              | String       | 16.04 |
|puppet_pe_version           | String       | 2016.4.2 |
|puppet_pe_consolepwd        | String       | password |
|puppet_pe_codemgrpwd        | String       | puppetlabs |
|proxy                       | String       | none (ex: http://myproxy.mycompany.com:8080) |
|aliases                     | String       | puppet |
|provider                    | String       | none (provide name of service provider for trusted facts) |
|platform                    | String       | Azure |

## `compile_master`

This template uses the `ubuntu_compile.sh` custom script to prepare three or more
servers to join a monolithic installation of Puppet Enterprise as compile masters.
The template includes a load balancer whose desired private IP address must be provided.
The Puppet Enterprise deployment's CA/Master needs to be specified by IP address as opposed to by name.

| Parameter Name | Type | Default |                                   
|----------------|------|---------|
|virtualMachineName          | String       | puppetcompile (will be indexed during deployment) |
|vmCount                     | Integer      | 3 |
|puppetServerIP              | String       | none (IP address of PE Master to join)|
|adminUserName               | String       | puppet |
|adminPassword               | SecureString | Puppet!Puppet |
|operatingSystemType         | String       | linux |
|virtualMachineSize          | String       | Standard_DS2_v2 |
|publisher                   | String       | Canonical |
|offer                       | String       | UbuntuServer |
|sku                         | String       | 16.04.0-LTS |
|storageAccountName          | String       | none (provide storage account for base VM disk) |
|diskStorageAccountName      | String       | none (provide storage account for VM data disks) |
|datadisk1size               | Int          | 30 (GB; used for /opt volume) |
|virtualNetworkName          | String       | none (provide existing virtual network name) |
|virtualNetworkResourceGroup | String       | none (provide the RG name where the virtual network is) |
|subnetName                  | String       | none (provide existing subnet from the virtual network) |
|customscriptName            | String       | ubuntu_puppet.sh |
|customscriptStorageAccount  | String       | none (provide storage account for custom script container) |
|diagnosticsStorageAccount   | String       | none (provide storage account for diagnostics data) |
|domain                      | String       | none (provide DNS domain name for server) |
|proxy                       | String       | none (ex: http://myproxy.mycompany.com:8080) |
|aliases                     | String       | puppet (comma-delimited list of PE deployment alias names)|
|provider                    | String       | Azure (provide name of service provider (no spaces) for trusted facts) |
|platform                    | String       | Azure |
