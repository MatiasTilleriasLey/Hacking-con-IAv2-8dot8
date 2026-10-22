# Lanzador único para AMBOS laboratorios (demo + examen) en Windows.
#
#   .\lab.ps1          construye + levanta ambos labs, muestra cómo conectarse
#   .\lab.ps1 down     detiene y elimina ambos labs
#
# Los puertos del host los elige Docker automáticamente (puerto libre al azar
# en 127.0.0.1), así nada choca con servicios que ya tengas corriendo. Este
# script lee de vuelta qué puertos eligió Docker y los muestra.
#
# Si PowerShell bloquea el script, corrélo una vez así:
#   powershell -ExecutionPolicy Bypass -File .\lab.ps1
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

function Invoke-Compose {
    param([string]$Dir, [string[]]$Args)
    Push-Location (Join-Path $PSScriptRoot $Dir)
    try { & docker compose @Args } finally { Pop-Location }
}

function Get-HostPort {
    param([string]$Dir, [string]$ContainerPort)
    Push-Location (Join-Path $PSScriptRoot $Dir)
    try {
        $line = (& docker compose port lab $ContainerPort 2>$null | Select-Object -First 1)
    } finally { Pop-Location }
    if ($line) { return ($line -split ':')[-1].Trim() }
    return "?"
}

if ($args.Count -gt 0 -and ($args[0] -eq 'down' -or $args[0] -eq 'stop')) {
    Write-Host "==> Deteniendo ambos labs..."
    Invoke-Compose -Dir 'demo' -Args @('down')
    Invoke-Compose -Dir 'exam' -Args @('down')
    Write-Host "Listo."
    exit 0
}

Write-Host "==> Construyendo y levantando el lab DEMO..."
Invoke-Compose -Dir 'demo' -Args @('up', '-d', '--build')

Write-Host "==> Construyendo y levantando el lab EXAMEN..."
Invoke-Compose -Dir 'exam' -Args @('up', '-d', '--build')

$demoWeb = Get-HostPort -Dir 'demo' -ContainerPort '80'
$demoFtp = Get-HostPort -Dir 'demo' -ContainerPort '21'
$examWeb = Get-HostPort -Dir 'exam' -ContainerPort '5000'

Write-Host ""
Write-Host "=================================================================="
Write-Host "  Laboratorios ARRIBA"
Write-Host "=================================================================="
Write-Host ""
Write-Host "Lab DEMO (recorrido en clase):"
Write-Host "  Web   : http://127.0.0.1:$demoWeb"
Write-Host "  FTP   : ftp 127.0.0.1 $demoFtp      (usuario: anonymous, sin contraseña)"
Write-Host "  (puertos de datos FTP pasivo: 21000-21010)"
Write-Host ""
Write-Host "Lab EXAMEN:"
Write-Host "  Web   : http://127.0.0.1:$examWeb"
Write-Host ""
Write-Host "Para detener todo:  .\lab.ps1 down"
