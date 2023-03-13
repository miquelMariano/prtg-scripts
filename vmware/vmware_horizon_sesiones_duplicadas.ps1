<# 
.DESCRIPTION
   Script para monitorizar con PRTG las sesiones duplicadas en VMware Horizon

.NOTES 
   File Name  : vmware_horizon_sesiones_duplicadas.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1
   
.PREREQUISITES   
   Instalar PowerCLI en el servidor PRTG > https://miquelmariano.github.io/2019/01/09/instalar-powerCLI-10-windows/
   Instalar funciones avanzadas > https://blogs.vmware.com/euc/2020/01/vmware-horizon-7-powercli.html

.USAGE
   .\vmware_horizon_sesiones_duplicadas.ps1 -cs 192.168.241.63 -user mydomain\username
   
.CHANGELOG
   v1 08/03/2023	Creación del script
   
#>

param(
    [string]$cs = "vdi.mycorp.com",
    [string]$user = "domain\miquel.mariano"
)

#--------------GLOBAL VARS----------------------
$prtg_format = "true" #True or False

$PathToCredentials = "C:\Users\admncora\Desktop\" #It is important not to put the last \

$now = Get-Date -format "dd-MM-yyyy_HHmmss"
$OutputDir = "C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML\log\"
$OutputFile = $now + "_" + $pool + "-stats.log"
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

$Cred = Get-Credentials $user $PathToCredentials
Connect-HVServer -Server $cs -credential $cred | out-null

$sesiones = (Get-HVLocalSession).namesdata | select username

$sesiones_totales = $sesiones | measure-object

$sesionesduplicadas = 0

$analizadas = New-Object System.Collections.ArrayList
$duplicadas = New-Object System.Collections.ArrayList

foreach ($sesion in $sesiones)
{
	if($analizadas.contains($sesion.username))
		{
	    $duplicadas.Add($sesion.username) > null
        Write-Host "$($sesion.username) tiene varias sesiones" -ForegroundColor Red
		$sesionesduplicadas++
		}
	else
		{
        $analizadas.Add($sesion.username) > null
	    }
}

$porcentage = (100 / $sesiones_totales.count) * $sesionesduplicadas

Write-Host "Detectados $sesionesduplicadas sesiones duplicadas de un total de $($sesiones_totales.count) > Porcentaje de un $porcentage"

foreach ($usuario in $duplicadas) {
	Get-HVLocalSession | Select @{N="User";E={$_.NamesData.UserName}}, @{N="DesktopName";E={$_.NamesData.MachineOrRDSServerName}}, @{N="AgentVersion";E={$_.NamesData.AgentVersion}}, @{N="ClientType";E={$_.NamesData.ClientType}}, @{N="SecurityGatewayLocation";E={$_.NamesData.SecurityGatewayLocation}}, @{N="ClientAddress";E={$_.NamesData.ClientAddress}}, @{N="ClientVersion";E={$_.NamesData.ClientVersion}}, @{N="ClientName";E={$_.NamesData.ClientName}}, @{N="Login";E={$_.sessiondata.StartTime.ToString($dtformat)}}, @{N="Disconnect";E={$_.sessiondata.DisconnectTime.ToString($dtformat)}} | where User -eq $usuario | ft -auto
	
}

Disconnect-HVServer $cs -Confirm:$False