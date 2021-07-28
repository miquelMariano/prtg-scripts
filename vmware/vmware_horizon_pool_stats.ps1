<# 
.DESCRIPTION
   This script collects VMware Horizon pool statistics to include into PRTG sensor

.NOTES 
   File Name  : vmware_horizon_pool_stats.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1
   
.PREREQUISITES   
   Install PowerCLI on PRTG sensor > https://miquelmariano.github.io/2019/01/09/instalar-powerCLI-10-windows/
   Install advanced functions > https://blogs.vmware.com/euc/2020/01/vmware-horizon-7-powercli.html

.USAGE
   .\vmware_horizon_pool_stats.ps1 -cs 192.168.241.63 -user mydomain\username -pool pool_name
   
.CHANGELOG
   v1 23/03/2021	Script creation
   v2 28/07/2021	Add more log detail as user logged by desktop and session details
  
#>

param(
    [string]$cs = "vdi.mycorp.com",
    [string]$user = "domain\miquel.mariano",
	[string]$pool = "IC-WS2019-VSAN"
)

#--------------GLOBAL VARS----------------------
$prtg_format = "true" #True or False

$PathToCredentials = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\ScriptCredentials" #It is important not to put the last \

$now = Get-Date -format "dd-MM-yyyy_HHmmss"
$OutputDir = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\log\"
$OutputFile = $now + "_" + $pool + "-stats.log"
#--------------GLOBAL VARS---------

#--------------IMPORT POWERSHELL MODULES----------------------
Import-Module "C:\PS6\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Common\11.5.0.14898112\VMware.VimAutomation.Common.psd1"
Import-Module "C:\PS6\VMware.Vim\6.7.0.14898114\VMware.Vim.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Cis.Core\11.5.0.14898113\VMware.VimAutomation.Cis.Core.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Sdk\11.5.0.14898111\VMware.VimAutomation.Sdk.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.Core\11.5.0.14899560\VMware.VimAutomation.Core.psd1"
Import-Module "C:\PS6\VMware.VimAutomation.HorizonView\7.10.0.14653756\VMware.VimAutomation.HorizonView.psm1"
Import-Module "C:\PS6\VMware.Hv.Helper\VMware.HV.Helper.psm1"
#--------------IMPORT POWERSHELL MODULES----------------------

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
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
$log = "`r`n$now Connecting to Connection Server $cs..." + $log

$Cred = Get-Credentials $user $PathToCredentials
Connect-HVServer -Server $cs -credential $cred | out-null

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Connection Server $cs connected well!" + $log

#$desktops = Get-HVMachineSummary -PoolName $pool
$desktops = Get-HVMachineSummary -PoolName $pool | select @{n="DESKTOPNAME";e={$_.base.name}},@{n="STATE";e={$_.base.basicstate}},@{n="ESXi";e={$_.managedmachinenamesdata.hostname}}
[int]$total = $desktops.count

ForEach ($desktop in $desktops){ 
  $sessiondata = (get-hvlocalsession).namesdata | where machineorrdsservername -eq $desktop.desktopname
  $now = Get-Date -format "dd-MM-yy HH:mm:ss | "
  $log = "`r`n$now Desktop "+ $desktop.desktopname + " is in a "+ $desktop.state + " state. Used by" + $sessiondata.username + " | Client type: " + $sessiondata.clienttype + " | Client IP: " + $sessiondata.clientaddress + " | Client name: " + $sessiondata.clientname + " | Client version: " + $sessiondata.clientversion + " | Client source: " + $sessiondata.securitygatewaylocation + "." + $log
#  if ( $desktop.base.basicstate -eq "ALREADY_USED" ) {
#     Remove-HVMachine -machinenames $desktop.base.name -deletefromdisk:$true -confirm:$false
#     $now = Get-Date -format "dd-MM-yy HH:mm:ss | "
#     $log = "`r`n$now IMPORTANT Deleting "+ $desktop.base.name + " because is in a "+ $desktop.base.basicstate + " state." + $log
#  }
}

##SESSION DATA VARIABLES
$sessiondataglobal = (get-hvlocalsession).namesdata | where desktoppoolcn -eq $pool
$externalconnection = ($sessiondataglobal | where {$_.securitygatewaylocation -eq "External"}).count
$internalconnection = ($sessiondataglobal | where {$_.securitygatewaylocation -eq "Internal"}).count
$unknownconnection = ($sessiondataglobal | where {$_.securitygatewaylocation -eq "Unknown"}).count
$windowsclient = ($sessiondataglobal | where {$_.clienttype -eq "Windows"}).count
$linuxclient = ($sessiondataglobal | where {$_.clienttype -eq "Linux"}).count
$macclient = ($sessiondataglobal | where {$_.clienttype -eq "Mac"}).count
$otherclient = ($sessiondataglobal | where {$_.clienttype -eq "Other"}).count
$clientversion4100 = ($sessiondataglobal | where {$_.clientversion -eq "4.10.0"}).count
$clientversion490 = ($sessiondataglobal | where {$_.clientversion -eq "4.9.0"}).count
$clientversion530 = ($sessiondataglobal | where {$_.clientversion -eq "5.3.0"}).count
$clientversion544= ($sessiondataglobal | where {$_.clientversion -eq "5.4.4"}).count
$clientversion800 = ($sessiondataglobal | where {$_.clientversion -eq "8.0.0"}).count
$clientversion830 = ($sessiondataglobal | where {$_.clientversion -eq "8.3.0"}).count

#DESKTOP STATUS VARIABLES
$Available = ($desktops | where {$_.state -eq "AVAILABLE"}).count;
$Connected = ($desktops | where {$_.state -eq "CONNECTED"}).count;
$Disconnected = ($desktops | where {$_.state -eq "DISCONNECTED"}).count;
$Maintenance = ($desktops | where {$_.state -eq "MAINTENANCE"}).count;
$Provisioning = ($desktops | where {$_.state -eq "PROVISIONING"}).count;
$Customizing = ($desktops | where {$_.state -eq "CUSTOMIZING"}).count;
$Already_Used = ($desktops | where {$_.state -eq "ALREADY_USED"}).count;
$Agent_Unreachable = ($desktops | where {$_.state -eq "AGENT_UNREACHABLE"}).count;
$Error = ($desktops | where {$_.state -eq "ERROR"}).count;
$Deleting = ($desktops | where {$_.state -eq "DELETING"}).count;
$Provisioning_Error = ($desktops | where {$_.base.state -eq "PROVISIONING_ERROR"}).count;

$all_states = $available + $connected + $disconnected + $maintenance + $provisioning + $customizing + $already_used + $agent_unreachable + $error + $deleting + $provisioning_error

#write-host Total VMs ------------------ $desktops.count
#write-host Disponibles ---------------- $available
write-host Conectadas ----------------- $connected
write-host Desconectadas -------------- $disconnected
#write-host Mantenimiento -------------- $maintenance
#write-host Provisionando -------------- $provisioning
#write-host Customizando --------------- $customizing
#write-host Ya en uso ------------------ $already_used
#write-host Agente indisponible -------- $agent_unreachable
#write-host Error ---------------------- $error
#write-host Eliminando ----------------- $deleting
#write-host Error de aprovisionamiento - $provisioning_error

###PRTG OUTPUT

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>Horizon pool $pool </text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Total Escritorios</channel> `n"
$XMLOutput += "<value>" + $desktops.count + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Escritorios disponibles </channel> `n"
$XMLOutput += "<value>"+ $available +"</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Sesiones conectadas</channel> `n"
$XMLOutput += "<value>" + $connected + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Sesiones desconectadas</channel> `n"
$XMLOutput += "<value>" + $disconnected + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Escritorios en mantenimiento</channel> `n"
$XMLOutput += "<value>" + $maintenance + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Provisioning</channel> `n"
$XMLOutput += "<value>" + $provisioning + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Customizando</channel> `n"
$XMLOutput += "<value>" + $customizing + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Ya en uso</channel> `n"
$XMLOutput += "<value>" + $already_used + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Agente inaccesible</channel> `n"
$XMLOutput += "<value>" + $agent_unreachable + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Escritorios con error</channel> `n"
$XMLOutput += "<value>" + $error + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Eliminando</channel> `n"
$XMLOutput += "<value>" + $deleting + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Error de provisionamiento</channel> `n"
$XMLOutput += "<value>" + $provisioning_error + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Suma de todos los estados</channel> `n"
$XMLOutput += "<value>" + $all_states + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes externos</channel> `n"
$XMLOutput += "<value>" + $externalconnection + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes internos</channel> `n"
$XMLOutput += "<value>" + $internalconnection + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes origen desconocido</channel> `n"
$XMLOutput += "<value>" + $unknownconnection + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes Windows</channel> `n"
$XMLOutput += "<value>" + $windowsclient + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes Linux</channel> `n"
$XMLOutput += "<value>" + $linuxclient + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes Mac</channel> `n"
$XMLOutput += "<value>" + $macclient + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes SO desconocido</channel> `n"
$XMLOutput += "<value>" + $otherclient + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes version 4.10.0</channel> `n"
$XMLOutput += "<value>" + $clientversion4100 + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes version 4.9.0</channel> `n"
$XMLOutput += "<value>" + $clientversion490 + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes version 5.3.0</channel> `n"
$XMLOutput += "<value>" + $clientversion530 + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes version 5.4.4</channel> `n"
$XMLOutput += "<value>" + $clientversion544 + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes version 8.0.0</channel> `n"
$XMLOutput += "<value>" + $clientversion800 + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>Clientes version 8.3.0</channel> `n"
$XMLOutput += "<value>" + $clientversion830 + "</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "</prtg>"

write-host $XMLOutput

$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Clients 8.3.0 -------------- $clientversion830" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Clients 8.0.0 -------------- $clientversion800" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Clients 5.4.4 -------------- $clientversion544" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Clients 5.3.0 -------------- $clientversion530" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Clients 4.10.0 ------------- $clientversion4100" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Clients 4.9.0 -------------- $clientversion490" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Other client --------------- $otherclient" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Mac client ----------------- $macclient" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Linux client --------------- $linuxclient" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Windows client ------------- $windowsclient" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Unknown source conection --- $unknownconnection" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Internal conection --------- $internalconnection" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now External conection --------- $externalconnection" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Provisioning error --------- $provisioning_error" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Deleting ------------------- $deleting" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Error ---------------------- $error" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Agent unreachable ---------- $agent_unreachable" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Alredy in use -------------- $already_used" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Customizing ---------------- $customizing" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Provisioning --------------- $provisioning" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Maintenance ---------------- $maintenance" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Disconnected --------------- $disconnected" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Connected ------------------ $connected" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Available ------------------ $available" + $log
$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Total VMs ------------------ $total" + $log


$now = Get-Date -format "dd-MM-yy HH:mm:ss | "
$log = "`r`n$now Disconnect Connection Server $cs!" + $log
Disconnect-HVServer $cs -Confirm:$False

$log | Out-File $OutputDir$OutputFile