<# 
.DESCRIPTION
   Lists all present snapshots older than a specified amount of days

   IMPORTANT: Requires VMware PowerCLI be installed.
   See: http://thesolving.com/virtualization/how-to-install-and-configure-vmware-powercli-version-10/

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

.PARAMETER IgnoreVMNamesStartingWith
    If specified, snapshots associated to Virtual Machine names beginning with this parameter (e.g. "replica") will be filtered from the result.
    If no parameter is specified or the string is empty, all snapshots (matching the MinAgeInDays criteria) will be included in the result.

.PARAMETER MinAgeInDays
    Only list snapshots with an age of at least x days. If the value is 0, the age is not considered in the result.

.EXAMPLE
    .\CheckForPresentVMwareSnapshots.ps1 -Server %host -Username "MyUsername" -Password "MyPassword" -IgnoreVMNamesStartingWith = "replica" -MinAgeInDays 3
    Values with % will be replaced by PRTG automatically.

.LINK
    https://miquelmariano.github.io
  
#>

param(
    [string]$Server = "192.168.6.10",
    [string]$Username = "miquel.mariano",
    [string]$Password = "Secret123!",
    [string]$IgnoreVMNamesStartingWith = "replica",
    [int]$MinAgeInDays = 50
)

Try
{
    $conn = Connect-VIServer $Server -Username $Username -Password $Password -Force

    $Snapshots = Get-VM | Get-Snapshot | Select VM, PowerState, Name,Description,@{Name="SizeGB";Expression={ [math]::Round($_.SizeGB,2) }},@{Name="Creator";Expression={ Get-SnapshotCreator -VM $_.VM -Created $_.Created }},Created,@{Name="Days";Expression={ (New-TimeSpan -End (Get-Date) -Start $_.Created).Days }} | where { $_.Days -ge $MinAgeInDays -and $_.powerstate -eq 'poweredon' } 

    $SnapshotsFiltered = @()
    Foreach ($Snapshot in $Snapshots)
    {
#        If($IgnoreVMNamesStartingWith.Length -gt 0 -and $Snapshot.VM.ToString().StartsWith($IgnoreVMNamesStartingWith))
#   write-host $snapshot.vm
#   If($IgnoreVMNamesStartingWith.Length -gt 0 -and $IgnoreVMNamesStartingWith -notcontains $Snapshot.VM)
#        {
            # Snapshot starts with ignored name. Skip entry.
#        } else {
            $SnapshotsFiltered += $Snapshot
#        }
    }

    Disconnect-VIServer $conn -Force -Confirm:$false

    if($SnapshotsFiltered.Length -eq 0)
    {
        Write-Host "0:No snapshots found with an age of at least $MinAgeInDays days."
        exit 0
    }

    $Result = $SnapshotsFiltered.Length.ToString() + ":" + $SnapshotsFiltered.Length.ToString() + " VMs poweredON with snapshots found with an age of at least $MinAgeInDays days >> "
    Foreach ($Snapshot in $SnapshotsFiltered)
    {
        $Result += "VM:" + $Snapshot.VM + ", Name:" + $Snapshot.Name + ", Description:" + $Snapshot.Description + ", Days: " + $Snapshot.Days + " ---- "
    }

    Write-Host $Result
    exit 1
}
catch
{
    Write-Host "-1:Error occurred while checking for snapshots:"$_.Exception.GetType().FullName, $_.Exception.Message. $_.Exception.Stacktrace
    exit 1
}