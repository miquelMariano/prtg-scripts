#Usar con PowerShell6
#Ignorelist: VMs con Snapshots que no queremos reportar
#Age: Dias que llevan los snapshots activos

Param(
[string]$ComputerName = "vcenter.empresa.local",
[string]$UserName = "administrator@vsphere.local",
[string]$Password = 'Passw0rd',
[string]$IgnoreList = 'VM1,VM2,VM3,VM4',
[string]$Age = '1'
)



#create credentials 
$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)

#Import-Module VMware.VimAutomation.Core >$Null
Add-PSSnapin VMware.VimAutomation.Core
Import-Module "C:\PS6\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Common\11.5.0.14898112\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Cis.Core\11.5.0.14898113\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Core\11.5.0.14899560\VMware.VimAutomation.Core.psd1"

Connect-VIServer -Server $ComputerName -UserName $UserName -Password $Password

$global:textvar = ""

$powerstate = [string]$Args[5]
$snapshot_count = 0


$IgnoreListSplit = $IgnoreList -Split ","

Get-VM -Location $Args[4] | Get-Snapshot | Where {$_.Name -notmatch "Restore Point \w" -and $IgnoreListSplit -notcontains $_.VM -and $_.Created -lt (Get-Date).AddDays(-$Age)} | `
#Get-VM -Location $Args[4] | Get-Snapshot | Where {$_.Name -notmatch "Restore Point \w"}


ForEach-Object {
	$snapshot_count = $snapshot_count+1
}





function get-snaps{
    $vms = get-vm | sort name
    $vmsnaps = @()
    foreach($vm in $vms){
    	$snap = Get-Snapshot $vm | Where {$_.Name -notmatch "Restore Point \w" -and $IgnoreListSplit -notcontains $_.VM -and $_.Created -lt (Get-Date).AddDays(-$Age)}
    	if($snap){
		  $vmsnaps += $vm
		  $snapshots = Get-Snapshot $vm
		  foreach ($snapshot in $snapshots){
          $global:textvar += $vm 
		  $global:textvar += "("
          $global:textvar += $snapshot.name
		  $global:textvar += "," 
		  $global:textvar += ([math]::Round($snapshot.sizemb/1024,2))
		  $global:textvar += ")"
		  $global:textvar += " - "

		}
    	}
    }
}
 
get-snaps


$x=[string]$snapshot_count+":"+$global:textvar

write-host "$snapshot_count"

if($snapshot_count -ne 0){

write-host "<prtg>"
write-host "<error>"
write-host "1"
write-host "</error>"
write-host "<text>"
write-host $global:textvar
write-host "</text>"
write-host "</prtg>"


}

if($snapshot_count -eq 0){

write-host "<prtg>"
write-host "<result>"
write-host "<channel>Snapshots running</channel>"
write-host "<value>"
write-host $snapshot_count
write-host "</value>"
write-host "<LimitMaxError>0</LimitMaxError>"
write-host "<LimitMode>1</LimitMode>"
write-host "</result>"
write-host "<text>"
write-host No Snapshots older than $Age days found
write-host "</text>"
write-host "</prtg>"


}