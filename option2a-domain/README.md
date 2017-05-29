# Dicker Data Deployment Template #2a

This template creates a VM, installes domain services, updates DNS of the VNet, downloads AD Connect so its ready to connect to an Azure Active Directory, deploys second VM and joins to domain

### REQUIREMENTS
1. Parameters

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fehhwerd%2Fphase1-domain-controller-plus-workload-vm%2Fmaster%2Foption2a-domain%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

</a>
This template creates one or two Windows Server 2012R2 VM(s) with IIS configured using DSC. It also installs one SQL Server 2014 standard edition VM, a VNET with two subnets, NSG, load balancer, NATing and probing rules.

## Resources
The following resources are created by this template:
- 1 or 2 Windows 2012R2 IIS Web Servers.
- 1 SQL Server 2014 running on premium or standard storage.
- 1 virtual network with 2 subnets with NSG rules.
- 1 storage account for the VHD files.
- 1 Availability Set for IIS servers.
- 1 Load balancer with NATing rules.


<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/iis-2vm-sql-1vm/images/resources.png" />


## Architecture Diagram
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/iis-2vm-sql-1vm/images/architecture.png" />

