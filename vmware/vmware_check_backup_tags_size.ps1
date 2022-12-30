<# 
.DESCRIPTION
   Monitoring total size VMs tagged

   IMPORTANT: Requires VMware PowerCLI be installed.
   See: https://miquelmariano.github.io/2019/01/09/instalar-powerCLI-10-windows/

   Use PRTG EXE/Script (Advanced) Sensor

.NOTES 
   File Name  : vmware_check_backup_tags_size.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1

   v1 29/09/2022  Script creation

.PARAMETER vCenter
    The name or ip address of the host or vCenter Server

.PARAMETER vCenteruser
    Name of the administrative account needed to authenticate to vSphere.

.PARAMETER Tag
    Tag defined on vCenter in format "category/tag name"    

.EXAMPLE
    .\vmware_check_backup_tags_size.ps1 -vCenter "vCenter" -vCenteruser "MyUsername" -tag "CATEGORIA/ETIQUETA"
  
#>

param(
    [string]$vCenter = "vcenter",
    [string]$vCenteruser = "administrator@vsphere.local",
	[string]$tag = "REPLICA-DIARIA/R-1900-L-S-3P-CPD106"
)

$PathToCredentials = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\ScriptCredentials\$vCenter" #It is important not to put the last \

#--------------IMPORT POWERSHELL MODULES | SET YOUR FOLDER LOCATION----------------------
Import-Module "C:\PS\VMware.VimAutomation.Sdk\12.5.0.19093564\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Common\12.6.0.19600917\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS\VMware.Vim\7.0.3.19601056\VMware.Vim.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Cis.Core\12.6.0.19601368\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Core\12.6.0.19601570\VMware.VimAutomation.Core.psd1"
#--------------IMPORT POWERSHELL MODULES | SET YOUR FOLDER LOCATION----------------------

#--------------SET POWERCLI CONFIGURATION----------------------
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
#--------------SET POWERCLI CONFIGURATION----------------------

#--------------ENCRYPT CREDENTIALS---------
#You must change these values to securely save your credential files
$Key = [byte]29,36,18,22,72,33,85,52,73,44,14,21,98,76,18,28

Function Get-Credentials {
    Param (
      [String]$AuthUser = $env:USERNAME,
        [string]$PathToCred
    )

    #Build the path to the credential file
    $Cred_File = $AuthUser.Replace("\","~")
    $File = $PathToCred + "\Credentials-$Cred_File.crd"
  #And find out if it's there, if not create it
    If (-not (Test-Path $File))
  { (Get-Credential $AuthUser).Password | ConvertFrom-SecureString -Key $Key | Set-Content $File
    }
  #Load the credential file 
    $Password = Get-Content $File | ConvertTo-SecureString -Key $Key
    $AuthUser = (Split-Path $File -Leaf).Substring(12).Replace("~","\")
    $AuthUser = $AuthUser.Substring(0,$AuthUser.Length - 4)
  $Credential = New-Object System.Management.Automation.PsCredential($AuthUser,$Password)
    Return $Credential
}
#--------------ENCRYPT CREDENTIALS---------

$Cred = Get-Credentials $vCenterUser $PathToCredentials
Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop | Out-Null

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

Disconnect-VIServer $vCenter -Confirm:$False