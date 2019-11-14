<# 
.DESCRIPTION
   Lists all present snapshots (on PoweredON VMs) older than a specified amount of days

   IMPORTANT: Requires VMware PowerCLI be installed.
   See: https://miquelmariano.github.io/2019/01/09/instalar-powerCLI-10-windows/

.NOTES 
   File Name  : vmware_check_snapshots.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1

   v1 13/11/2019  Script creation

.PARAMETER Server
    The name or ip address of the host or vCenter Server

.PARAMETER Username
    Name of the administrative account needed to authenticate to vSphere.

.PARAMETER Password
    The password for the given user.

.PARAMETER IgnoreList
    List of VMs excluded     

.PARAMETER MinAgeInDays
    Only list snapshots with an age of at least x days. If the value is 0, the age is not considered in the result.

.EXAMPLE
    .\vmware_check_snapshots.ps1 -Server %host -Username "MyUsername" -password "Password" -MinAgeInDays 3 -IgnoreList "replica|plantilla"
    Values with % will be replaced by PRTG automatically.

  
#>

param(
    [string]$Server = "vCenter",
    [string]$Username = "administrator@vsphere.local",
    [string]$Password = "password.",
    [string]$IgnoreList = "VM1|VM2|VM3",
    [int]$MinAgeInDays = 0
)


Import-Module "C:\PS6\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Common\11.5.0.14898112\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS6\VMware.Vim\6.7.0.14898114\VMware.Vim.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Cis.Core\11.5.0.14898113\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Core\11.5.0.14899560\VMware.VimAutomation.Core.psd1"



    $conn = Connect-VIServer $Server -Username $Username -Password $Password -Force

    $Snapshots = Get-VM | Get-Snapshot | Select VM, Name,Description,@{Name="SizeGB";Expression={ [math]::Round($_.SizeGB,2) }},@{Name="Creator";Expression={ Get-SnapshotCreator -VM $_.VM -Created $_.Created }},Created,@{Name="Days";Expression={ (New-TimeSpan -End (Get-Date) -Start $_.Created).Days }} | where { $_.Days -ge $MinAgeInDays }
 
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

    Disconnect-VIServer $conn -Force -Confirm:$false

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