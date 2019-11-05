<# 
.DESCRIPTION
   This script checks ESXi dead LUN path

.NOTES 
   File Name  : dead-lun-path.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 3

.USAGE
   Execute directly
   
.CHANGELOG
   v1 20/04/2017  Script creation
   v2 07/07/2017  Formatting log output
   v3 16/10/2017  Formatting for blog post > https://miquelmariano.github.io/2017/10/18/check-ESXi-dead-lun-path/
  
#>

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Start Check" + $log

#Verify that PowerCLI is installed
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}

#--------------GLOBAL VARS----------------------
$vCenter = "10.20.20.252"
$vCenteruser ="administrator@vsphere.local"

$PathToCredentials = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML" #It is important not to put the last \

$OutputDir = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\log\"
$OutputFile = "aaa---tata-dead-lun-path-debug.log"
#--------------GLOBAL VARS---------


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

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Connecting vCenter..." + $log

$Cred = Get-Credentials $vCenterUser $PathToCredentials
Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop | Out-Null

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now vCenter connected!" + $log

$totaldeadpaths = 0
$sum_totaldeadpaths = 0

ForEach ($vmhost in get-datacenter aaa---tata | Get-Vmhost){ 
  $now = Get-Date -format "dd-MM-yy HH:mm:ss | "
  $log = "`r`n$now Starting analysis of ESXi "+ $vmhost.name + " analyze | " + $log
  #write-host $vmhost.name
  $deadpaths = Get-ScsiLun -vmhost $vmhost | Get-ScsiLunPath | where {$_.State -eq "Dead"} | Select ScsiLun,State
  $now = Get-Date -format "dd-MM-yy HH:mm:ss | "
  $log = "`r`n$now "+ $deadpaths.scsilun + "|" + $deadpaths.state + "|" + $log
  #write-Host $deadpaths
  $totaldeadpaths = $deadpaths | measure-object | select count
  $now = Get-Date -format "dd-MM-yy HH:mm:ss | "
  $log = "`r`n$now " + $totaldeadpaths.count + " paths down on " + $vmhost.name + $log
  #write-Host $totaldeadpaths.count
  $sum_totaldeadpaths = $sum_totaldeadpaths + $totaldeadpaths.count
  }
#write-Host $sum_totaldeadpaths

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Disconnect vCenter server!" + $log
Disconnect-VIServer $vCenter -Confirm:$False


$log | Out-File $OutputDir$OutputFile

###PRTG OUTPUT

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>check_storage_dead_paths</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Total dead paths</channel> `n"
$XMLOutput += "<value>" + $sum_totaldeadpaths + "</value>`n"
$XMLOutput += "</result>`n"


$XMLOutput += "</prtg>"

write-host $XMLOutput
