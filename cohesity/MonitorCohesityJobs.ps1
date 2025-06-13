param(
    [string]$JobName = "Powerscale Files"  # Parámetro con valor por defecto
)

# Configuración del clúster Cohesity
$CohesityCluster = "https://cohesityzamudiotech.ingeteam.local"
$Username = 'prtg'
$Password = 'AM8qil0g45y^b9b#'
$Domain = 'LOCAL'  # Cambia según tu dominio (e.g., "LOCAL" o el nombre del dominio)

# Deshabilitar verificación de certificados SSL (para certificados autofirmados)
if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
    Add-Type -TypeDefinition @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@ -Language CSharp
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

# Autenticación en Cohesity API
$AuthUrl = "$CohesityCluster/irisservices/api/v1/public/accessTokens"
$Body = @{
    username = $Username
    password = $Password
    domain   = $Domain
}

try {
    $AuthResponse = Invoke-RestMethod -Uri $AuthUrl -Method POST -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json"
    $Token = $AuthResponse.accessToken
} catch {
    Write-Host "<prtg><error>1</error><text>Error en la autenticación de Cohesity: $_</text></prtg>"
    exit 2
}

# Obtener lista de trabajos de protección
$JobsUrl = "$CohesityCluster/irisservices/api/v1/public/protectionJobs"
$Headers = @{ Authorization = "Bearer $Token" }

try {
    $JobsResponse = Invoke-RestMethod -Uri $JobsUrl -Method GET -Headers $Headers
} catch {
    Write-Host "<prtg><error>1</error><text>Error al obtener trabajos de protección: $_</text></prtg>"
    exit 2
}

# Filtrar el trabajo específico
$Job = $JobsResponse | Where-Object { $_.name -eq $JobName }

if (-not $Job) {
    Write-Host "<prtg><error>1</error><text>Trabajo '$JobName' no encontrado</text></prtg>"
    exit 1
}

# Obtener el ID del trabajo
$JobId = $Job.id

# Obtener la última ejecución del trabajo
$RunsUrl = "$CohesityCluster/irisservices/api/v1/public/protectionRuns?jobId=$JobId&limit=1"

try {
    $RunsResponse = Invoke-RestMethod -Uri $RunsUrl -Method GET -Headers $Headers
} catch {
    Write-Host "<prtg><error>1</error><text>Error al obtener ejecuciones del trabajo '$JobName': $_</text></prtg>"
    exit 2
}

# Verificar si hay ejecuciones disponibles
if (-not $RunsResponse -or $RunsResponse.Count -eq 0) {
    Write-Host "<prtg><error>1</error><text>No hay ejecuciones recientes para '$JobName'</text></prtg>"
    exit 1
}

# Obtener la última ejecución
$LatestRun = $RunsResponse[0]  # Solo se devuelve un elemento debido al "limit=1"

# Obtener el estado del último run
$JobStatus = $LatestRun.backupRun.status

# Obtener las fechas de inicio y final en microsegundos (Epoch en bruto)
$StartTimeUsecs = $LatestRun.backupRun.stats.startTimeUsecs
$EndTimeUsecs = $LatestRun.backupRun.stats.endTimeUsecs

# Convertir estado a número para PRTG (actualizado para los códigos con "k")
$StatusCode = @{
    "kRunning"   = 1
    "kSucceeded" = 0
    "kFailure"    = 2
    "kCanceled"  = 3
    "kPaused"    = 4
    "kQueued"    = 5
}[$JobStatus]

# Función para convertir Epoch (microsegundos) a fecha legible
function ConvertFrom-Epoch {
    param([long]$epochMicroseconds)
    
    # Convertir microsegundos a segundos
    $epochSeconds = $epochMicroseconds / 1000000
    
    # Convertir a formato de fecha legible
    return [System.DateTimeOffset]::FromUnixTimeSeconds($epochSeconds).AddHours(1).DateTime.ToString("yyyy-MM-dd HH:mm:ss")  # Agregar 1 hora para UTC+1
}

# Convertir las fechas de inicio y fin a formato de fecha legible
$StartTime = ConvertFrom-Epoch -epochMicroseconds $StartTimeUsecs
$EndTime = if ($JobStatus -eq "kRunning") { "En ejecución" } else { ConvertFrom-Epoch -epochMicroseconds $EndTimeUsecs }

# Obtener la fecha y hora actual (UTC +1)
$now = (Get-Date).AddHours(1).ToString("yyyy-MM-dd HH:mm:ss")

# Calcular la diferencia entre el inicio y el tiempo actual (en minutos), solo si el estado es kRunning
$RunningTimeInMinutes = 0
if ($JobStatus -eq "kRunning") {
    $StartTimeDate = [datetime]::ParseExact($StartTime, "yyyy-MM-dd HH:mm:ss", $null)
    $nowDate = [datetime]::ParseExact($now, "yyyy-MM-dd HH:mm:ss", $null)

    $TimeSpan = $nowDate - $StartTimeDate
    $RunningTimeInMinutes = [math]::Round($TimeSpan.TotalMinutes)

    # Restar 60 minutos si el estado es kRunning (corrigiendo la diferencia de zona horaria UTC a UTC+1)
    $RunningTimeInMinutes = $RunningTimeInMinutes - 60
}

# Salida en XML para PRTG
Write-Host "<prtg>"

# Canal 1: Estado del trabajo
Write-Host "<result>"
Write-Host "<channel>Backup Status ($JobName)</channel>"
Write-Host "<value>$StatusCode</value>"
Write-Host "<limitmaxerror>1</limitmaxerror>"
Write-Host "<limitmaxwarning>0</limitmaxwarning>"
Write-Host "</result>"

# Canal 2: Fecha de inicio (Epoch en bruto)
Write-Host "<result>"
Write-Host "<channel>Backup Start Time ($JobName)</channel>"
Write-Host "<value>$StartTimeUsecs</value>"
Write-Host "<limitmaxerror>0</limitmaxerror>"
Write-Host "<limitmaxwarning>0</limitmaxwarning>"
Write-Host "</result>"

# Canal 3: Fecha de finalización (Epoch en bruto)
Write-Host "<result>"
Write-Host "<channel>Backup End Time ($JobName)</channel>"
Write-Host "<value>$EndTimeUsecs</value>"
Write-Host "<limitmaxerror>0</limitmaxerror>"
Write-Host "<limitmaxwarning>0</limitmaxwarning>"
Write-Host "</result>"

# Canal 4: Tiempo transcurrido en kRunning (en minutos)
Write-Host "<result>"
Write-Host "<channel>Backup Running Time ($JobName)</channel>"
Write-Host "<value>$RunningTimeInMinutes</value>"
Write-Host "<limitmaxerror>1</limitmaxerror>"
Write-Host "<limitmaxwarning>0</limitmaxwarning>"
Write-Host "</result>"

# Mensaje detallado del estado (con fechas convertidas a formato legible)
if ($JobStatus -eq "kRunning") {
    Write-Host "<text>Trabajo: $JobName | Estado: $JobStatus | Inicio: $StartTime | Fin: En ejecución | Tiempo en kRunning: $RunningTimeInMinutes minutos</text>"
} else {
    Write-Host "<text>Trabajo: $JobName | Estado: $JobStatus | Inicio: $StartTime | Fin: $EndTime</text>"
}

Write-Host "</prtg>"

exit $StatusCode
