<# 
.DESCRIPTION
   Lists all present snapshots (on PoweredON VMs) older than a specified amount of days

   IMPORTANT: Requires VMware PowerCLI be installed.
   See: https://miquelmariano.github.io/2019/01/09/instalar-powerCLI-10-windows/

.NOTES 
   File Name  : vmware_check_snapshots.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1

   v1 13/11/2019  Script creation.

.EXAMPLE
    .\vmware_check_snapshots.ps1 -vCenter vcenter.lab.local -vCenteruser "MyUsername" -MinAgeInDays 3 -IgnoreList "replica|plantilla" -datacenter datacenter_name
    Values with % will be replaced by PRTG automatically.

  
#>

#--------------GLOBAL VARS----------------------
param(
    [string]$vCenter = "vCenter",
    [string]$vCenteruser = "administrator@vsphere.local",
    [string]$IgnoreList = "VM1|VM2|VM3",
    [string]$datacenter = "datacenter",
    [int]$MinAgeInDays = 0
)

$PathToCredentials = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\ScriptCredentials\$vCenter" #It is important not to put the last \
#--------------GLOBAL VARS---------


#--------------IMPORT POWERSHELL MODULES----------------------
Import-Module "C:\PS\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Common\11.5.0.14898112\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS\VMware.Vim\6.7.0.14898114\VMware.Vim.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Cis.Core\11.5.0.14898113\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS\VMware.VimAutomation.Core\11.5.0.14899560\VMware.VimAutomation.Core.psd1"
#--------------IMPORT POWERSHELL MODULES----------------------

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false


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

    $Snapshots = Get-Datacenter $datacenter | Get-VM | Get-Snapshot | Select VM, Name,Description,@{Name="SizeGB";Expression={ [math]::Round($_.SizeGB,2) }},@{Name="Creator";Expression={ Get-SnapshotCreator -VM $_.VM -Created $_.Created }},Created,@{Name="Days";Expression={ (New-TimeSpan -End (Get-Date) -Start $_.Created).Days }} | where { $_.Days -ge $MinAgeInDays }
 
    $SnapshotsFiltered = @()
    Foreach ($Snapshot in $Snapshots)
    {
        If($IgnoreList.Length -gt 0 -and $Snapshot.VM -match $IgnoreList)
        {
            # Snapshot starts with ignored name. Skip entry.
        } else {
            $SnapshotsFiltered += $Snapshot
        }
    }

Disconnect-VIServer $vCenter -Confirm:$False

    if($SnapshotsFiltered.Length -eq 0)
    {
        Write-Host "0:No snapshots found with an age of at least $MinAgeInDays days."
        exit 0
    }

    $Result = $SnapshotsFiltered.Length.ToString() + ":"
    Foreach ($Snapshot in $SnapshotsFiltered)
    {
        $Result += "VM:" + $Snapshot.VM + ", Name:" + $Snapshot.Name + ", Description:" + $Snapshot.Description + ", Days: " + $Snapshot.Days + " ---- "
    }

    Write-Host $Result
    exit 1