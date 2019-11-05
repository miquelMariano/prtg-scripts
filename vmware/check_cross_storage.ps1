<# 
.DESCRIPTION
   This script checks cross-storage between datacenters

.NOTES 
   File Name  : Check_cross-storage.ps1 
   Author     : Miquel Mariano - @miquelMariano
   Version    : 2

.USAGE
	Execute directly
   
.CHANGELOG
   v1	23/11/2016	Script creation
   v2	
  
#>

$now = Get-Date -format "dd-MM-yyyy HH:mm:ss | "
$log = "`r`n$now Start Check" + $log

#Verify if PowerCLI are installed
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}

#--------------GLOBAL VARS----------------------
$vCenter = "10.20.20.252"
$vCenteruser ="administrator@vsphere.local"

$PathToCredentials = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML" #It is important not to put the last \
#--------------GLOBAL VARS----------------------


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

$vms = get-datacenter aaa---tata | get-vm
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


$now = Get-Date -format "ddMMyyyy_HHmmss"
$dir = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\log\"
$file = $now + "_check_cross-storage_debug.log"
$log | Out-File $dir$file


###PRTG OUTPUT

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>check_cross_storage</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Num_inconsistencies</channel> `n"
$XMLOutput += "<value>" + $measure.count + "</value>`n"
$XMLOutput += "</result>`n"


$XMLOutput += "</prtg>"

write-host $XMLOutput

