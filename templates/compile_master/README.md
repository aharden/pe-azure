# Puppet Enterprise Compile Master Template

This template deploys Ubuntu 16.04 LTS servers configured to run Puppet
Enterprise.

This template uses the `containers/custom/ubuntu_compile.sh` custom script to prepare multiple
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
