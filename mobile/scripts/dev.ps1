# Keeps Flutter running and auto hot-reloads when lib/ files change.
# Usage: npm run dev   (from mobile folder)

$ErrorActionPreference = "Stop"
$mobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $mobileRoot

$apiUrl = if ($env:API_URL) { $env:API_URL } else { "http://localhost:5000" }
$device = if ($env:FLUTTER_DEVICE) { $env:FLUTTER_DEVICE } else { "chrome" }

Write-Host ""
Write-Host "  MacallinAI Mobile — auto reload dev mode" -ForegroundColor Cyan
Write-Host "  Device : $device"
Write-Host "  API    : $apiUrl"
Write-Host "  Saves in lib/ trigger hot reload automatically"
Write-Host ""

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "flutter"
$psi.Arguments = "run -d $device --dart-define=API_URL=$apiUrl"
$psi.WorkingDirectory = $mobileRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true

$flutter = New-Object System.Diagnostics.Process
$flutter.StartInfo = $psi
[void]$flutter.Start()

# Print flutter output without blocking reload loop
$outputAction = {
  while ($true) {
    if ($flutter.HasExited) { break }
    $line = $flutter.StandardOutput.ReadLine()
    if ($null -eq $line) { Start-Sleep -Milliseconds 100; continue }
    Write-Host $line
  }
}
Start-Job -ScriptBlock $outputAction | Out-Null

function Get-LibFingerprint {
  $files = Get-ChildItem -Path (Join-Path $mobileRoot "lib") -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue
  if (-not $files) { return "" }
  return ($files | ForEach-Object { "$($_.Name):$($_.LastWriteTimeUtc.Ticks)" }) -join '|'
}

function Send-HotReload {
  if ($flutter.HasExited) { return }
  try {
    $flutter.StandardInput.WriteLine('r')
    $flutter.StandardInput.Flush()
    Write-Host "[dev] Hot reload" -ForegroundColor Green
  } catch {
    Write-Host "[dev] Reload skipped" -ForegroundColor DarkYellow
  }
}

$fingerprint = Get-LibFingerprint
Write-Host "Flutter PID $($flutter.Id) — watching lib/ ..." -ForegroundColor DarkGray
Write-Host ""

try {
  while (-not $flutter.HasExited) {
    Start-Sleep -Milliseconds 700
    $newFingerprint = Get-LibFingerprint
    if ($newFingerprint -ne $fingerprint -and $fingerprint -ne "") {
      Send-HotReload
    }
    $fingerprint = $newFingerprint
  }
} finally {
  if (-not $flutter.HasExited) {
    $flutter.Kill()
  }
  Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
}
