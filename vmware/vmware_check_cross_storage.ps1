<# 
.DESCRIPTION
   This script checks cross-storage between datacenters

   Use PRTG EXE/Script Advanced Sensor

.NOTES 
   File Name  : vmware_check_cross_storage.ps1 
   Author     : Miquel Mariano - @miquelMariano
   Version    : 2

   v1   23/11/2016    Script creation
   v2   11/05/2020    Add Set-PowerCLIConfiguration section. Mandatory with  PRTG

.EXAMPLE
    .\vmware_check_cross_storage.ps1 -vCenter 192.168.241.63 -vCenteruser administrator@vsphere.local -datacenter datacenter_name
	
#>

#--------------GLOBAL VARS----------------------
param(
    [string]$vCenter = "ip",
    [string]$vCenteruser = "administrator@vsphere.local",
  [string]$datacenter = "datacenter"
)

$PathToCredentials = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\ScriptCredentials\$vCenter" #It is important not to put the last \

$now = Get-Date -format "dd-MM-yyyy_HHmmss"
$OutputDir = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\log\"
$OutputFile = $now + "_" + $datacenter + "-check-cross-storage.log"
#--------------GLOBAL VARS----------------------

#--------------IMPORT POWERSHELL MODULES----------------------
Import-Module "C:\PS\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Common\11.5.0.14898112\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS\VMware.Vim\6.7.0.14898114\VMware.Vim.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Cis.Core\11.5.0.14898113\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Core\11.5.0.14899560\VMware.VimAutomation.Core.psd1"
#--------------IMPORT POWERSHELL MODULES----------------------

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now Start Check" + $log

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
	{	(Get-Credential $AuthUser).Password | ConvertFrom-SecureString -Key $Key | Set-Content $File
    }
	#Load the credential file 
    $Password = Get-Content $File | ConvertTo-SecureString -Key $Key
    $AuthUser = (Split-Path $File -Leaf).Substring(12).Replace("~","\")
    $AuthUser = $AuthUser.Substring(0,$AuthUser.Length - 4)
	$Credential = New-Object System.Management.Automation.PsCredential($AuthUser,$Password)
    Return $Credential
}
#--------------ENCRYPT CREDENTIALS---------

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now Connecting vCenter..." + $log

$Cred = Get-Credentials $vCenterUser $PathToCredentials
Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop | Out-Null

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now vCenter connected!" + $log

$vms = get-datacenter $datacenter | get-vm
$VMsFilteredArray = @("")
$NothingToDo = 0

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now Loading VM name, ESXi host and datastore info to array..." + $log

foreach ($vm in $vms) {
	$VMsFilteredArray += Get-VM $vm | Select Name, powerstate, VMHost, @{N="Datastore";E={Get-datastore -VM $_}} | Where-Object datastore -notlike "GAD*"
}

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now Array loaded succesfuly!" + $log
$log = "`r`n$now Looking inconsistencies..." + $log

$total = $VMsFilteredArray | Where-Object {($_.vmhost -like "ta*" -and $_.datastore -notlike "TA*") -or ($_.vmhost -like "sa*" -and $_.datastore -notlike "SA*")}
                                           
$measure = $total | measure-object
if ($measure.count -gt 0) {
	$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
    $log = "`r`n$now Found " + $measure.count + " inconsistencies" + $log
	$NothingToDo = 1
	foreach ($item in $total) {
		if ($item.datastore -notlike "TA*") {
		#write-host "Moving $item to GS storage" -foregroundcolor red -backgroundcolor yellow
		$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
#        $log = "`r`n$now Moving "+ $item.name + " to GS storage" + $log
	    $log = "`r`n$now "+ $item.name + " inventoried in "+ $item.vmhost +" and stored in "+ $item.datastore +". It is necessary to move it!!!" + $log
		#move-vm $item.name -datastore gs_simplex
		} else {
		#write-host "Moving $item to IX storage" -foregroundcolor red -backgroundcolor yellow
		$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
#        $log = "`r`n$now Moving "+ $item.name +" to IX storage" + $log
		$log = "`r`n$now "+ $item.name + " inventoried in "+ $item.vmhost +" and stored in "+ $item.datastore +". It is necessary to move it!!!" + $log
		#move-vm $item.name -datastore ix_simplex
		#Get-VM $item.name | Move-VM -datastore (Get-datastore ix_simplex)
        }
	}		
}

if ($NothingToDo -eq 0) {
	#write-host "Nothing to do!" -foregroundcolor white -backgroundcolor green
	$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
	$log = "`r`n$now Nothing to do!" + $log
}

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now Disconnect vCenter server!" + $log
Disconnect-VIServer $vCenter -Confirm:$False




$log | Out-File $OutputDir$OutputFile

###PRTG OUTPUT

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>check_cross_storage</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Num_inconsistencies</channel> `n"
$XMLOutput += "<value>" + $measure.count + "</value>`n"
$XMLOutput += "</result>`n"


$XMLOutput += "</prtg>"

write-host $XMLOutput


