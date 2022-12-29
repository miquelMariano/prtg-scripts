<# 
.DESCRIPTION
   Monitoring total size VMs tagged

   IMPORTANT: Requires VMware PowerCLI be installed.
   See: https://miquelmariano.github.io/2019/01/09/instalar-powerCLI-10-windows/

.NOTES 
   File Name  : vmware_check_backup_tags_size.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1

   v1 29/09/2022  Script creation

.PARAMETER Server
    The name or ip address of the host or vCenter Server

.PARAMETER Username
    Name of the administrative account needed to authenticate to vSphere.

.PARAMETER Password
    The password for the given user.

.PARAMETER Tag
    Tag defined on vCenter in format "category/tag name"    

.EXAMPLE
    .\vmware_check_snapshots.ps1 -Server "vCenter" -Username "MyUsername" -password "Password" -tag "CATEGORIA/ETIQUETA"
  
#>

param(
    [string]$Server = "vcenter",
    [string]$Username = "administrator@vsphere.local",
    [string]$Password = "password",
	[string]$tag = "REPLICA-DIARIA/R-1900-L-S-3P-CPD106"
)

#--------------IMPORT POWERSHELL MODULES----------------------
Import-Module "C:\PS\VMware.VimAutomation.Sdk\12.5.0.19093564\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Common\12.6.0.19600917\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS\VMware.Vim\7.0.3.19601056\VMware.Vim.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Cis.Core\12.6.0.19601368\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Core\12.6.0.19601570\VMware.VimAutomation.Core.psd1"
#--------------IMPORT POWERSHELL MODULES----------------------

$conn = Connect-VIServer $Server -Username $Username -Password $Password -Force 

$TaggedVM = Get-VM | Get-TagAssignment | where {$_.Tag -like $tag }
$TotalVMDKsize = 0

#write-host "Total VMs con etiqueta " $tag " = " $TaggedVM.count

    Foreach ($item in $taggedvm)
	{
	  $vm = Get-VM -name $item.entity | Select-Object Name,@{n="vmdk"; e={(Get-HardDisk -VM $_ | Measure-Object -Sum CapacityGB).Sum}}
	  $TotalVMDKsize = $TotalVMDKsize + $vm.vmdk
#	  write-host "VM > " $vm.name " = " $vm.vmdk
	}
	
#	write-host "Total = " $totalvmdksize
	 
$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>Tamaño VMs con etiqueta $tag </text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Tamaño total VMs </channel> `n"
$XMLOutput += "<value>"+ [Math]::Truncate($totalvmdksize) +"</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Numero de VMs</channel> `n"
$XMLOutput += "<value>" + $TaggedVM.count + "</value>`n"
$XMLOutput += "</result>`n"



$XMLOutput += "</prtg>"

write-host $XMLOutput