# Auto hot-reload dev mode for MacallinAI mobile.
# Keeps `flutter run` alive and sends "r" when lib/*.dart files change.
#
# Usage (from mobile/):
#   npm run dev
#
# Stop any other `flutter run` first to avoid port conflicts.

$ErrorActionPreference = "Stop"
$mobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $mobileRoot

$apiUrl = if ($env:API_URL) { $env:API_URL } else { "http://localhost:5000" }
$device = if ($env:FLUTTER_DEVICE) { $env:FLUTTER_DEVICE } else { "chrome" }
$flutterExe = (Get-Command flutter -ErrorAction Stop).Source

Write-Host ""
Write-Host "MacallinAI Mobile - auto reload ON" -ForegroundColor Cyan
Write-Host "  Device : $device"
Write-Host "  API    : $apiUrl"
Write-Host ""

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $flutterExe
$psi.Arguments = "run -d $device --dart-define=API_URL=$apiUrl"
$psi.WorkingDirectory = $mobileRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $false

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
$proc.EnableRaisingEvents = $true

$null = $proc.add_OutputDataReceived({ param($s, $e) if ($e.Data) { Write-Host $e.Data } })
$null = $proc.add_ErrorDataReceived({ param($s, $e) if ($e.Data) { Write-Host $e.Data -ForegroundColor DarkYellow } })

if (-not $proc.Start()) {
  Write-Host "Failed to start Flutter. Close other flutter run sessions and retry." -ForegroundColor Red
  exit 1
}

$proc.BeginOutputReadLine()
$proc.BeginErrorReadLine()

function Get-LibFingerprint {
  $libPath = Join-Path $mobileRoot "lib"
  $files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue
  if (-not $files) { return "" }
  $parts = @()
  foreach ($f in $files) {
    $parts += ($f.Name + ":" + $f.LastWriteTimeUtc.Ticks)
  }
  return ($parts -join "|")
}

function Send-HotReload {
  if ($proc.HasExited) { return }
  try {
    $proc.StandardInput.WriteLine("r")
    $proc.StandardInput.Flush()
    Write-Host "[dev] hot reload" -ForegroundColor Green
  } catch {
    Write-Host "[dev] reload skipped" -ForegroundColor DarkYellow
  }
}

$fp = Get-LibFingerprint
Write-Host "Flutter PID $($proc.Id) - watching lib/" -ForegroundColor DarkGray
Write-Host ""

try {
  while (-not $proc.HasExited) {
    Start-Sleep -Milliseconds 700
    $newFp = Get-LibFingerprint
    if ($newFp -ne $fp -and $fp -ne "") {
      Send-HotReload
    }
    $fp = $newFp
  }
} finally {
  if (-not $proc.HasExited) {
    $proc.Kill()
  }
}
