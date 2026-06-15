param(
  [int]$Hours = 8,
  [int]$PollSeconds = 20,
  [int]$Iterations = 50,
  [int]$Warmup = 3,
  [string]$DeviceLabel = "MBH-N49"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$WorkspaceRoot = Resolve-Path (Join-Path $ProjectRoot "..")
$Adb = Join-Path $WorkspaceRoot "01-sustained-mobile-inference\tools\android\platform-tools\adb.exe"
$Resume = Join-Path $ProjectRoot "scripts\resume_phone_strict_backend_matrix.ps1"
$Validator = Join-Path $ProjectRoot "scripts\mobile_benchmark_validator.py"
$StatusDir = Join-Path $ProjectRoot "artifacts\phone-strict-repeat-waiter"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null
$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "runner.log"
$Start = Get-Date
$Deadline = $Start.AddHours($Hours)
$RunPrefix = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$DeviceLabel-bai4-strict-repeat"

function Write-Status {
  param([string]$State, [string]$Step, [string]$Serial = "", [string]$Notes = "")
  $now = Get-Date
  $progress = [Math]::Min(100.0, [Math]::Round(100.0 * (($now - $Start).TotalSeconds) / [Math]::Max(1.0, ($Deadline - $Start).TotalSeconds), 2))
  $obj = [ordered]@{
    state = $State
    progress_percent_time = $progress
    current_step = $Step
    device_serial = $Serial
    run_prefix = $RunPrefix
    started_at = $Start.ToString("o")
    deadline = $Deadline.ToString("o")
    updated_at = $now.ToString("o")
    notes = $Notes
  }
  $obj | ConvertTo-Json | Set-Content -Encoding UTF8 $StatusPath
  @(
    "# Bài 4 phone strict repeat waiter",
    "",
    "- State: ``$State``",
    "- Progress by time: $progress%",
    "- Current step: ``$Step``",
    "- Device serial: ``$Serial``",
    "- Run prefix: ``$RunPrefix``",
    "- Started: $($Start.ToString("yyyy-MM-dd HH:mm:ss zzz"))",
    "- Deadline: $($Deadline.ToString("yyyy-MM-dd HH:mm:ss zzz"))",
    "- Updated: $($now.ToString("yyyy-MM-dd HH:mm:ss zzz"))",
    "- Notes: $Notes"
  ) | Set-Content -Encoding UTF8 $LivePath
}

function Get-Device {
  if (-not (Test-Path $Adb)) { return "" }
  $lines = & $Adb devices 2>$null
  foreach ($line in $lines) {
    if ($line -match '^(\S+)\s+device\b') { return $Matches[1] }
  }
  return ""
}

Write-Status -State "waiting" -Step "waiting-for-adb" -Notes "Waiting for ADB-visible phone."
& $Adb start-server | Add-Content -Encoding UTF8 $LogPath

$serial = ""
while ((Get-Date) -lt $Deadline) {
  $serial = Get-Device
  if ($serial) { break }
  Write-Status -State "waiting" -Step "waiting-for-adb" -Notes "No ADB device. Connect phone and authorize USB debugging."
  Start-Sleep -Seconds $PollSeconds
}

if (-not $serial) {
  Write-Status -State "failed" -Step "no-device" -Notes "No ADB device before deadline."
  exit 2
}

Write-Status -State "running" -Step "strict-repeat" -Serial $serial -Notes "ADB device found. Running strict repeat matrix."
powershell -ExecutionPolicy Bypass -File $Resume `
  -RunPrefix $RunPrefix `
  -DeviceSerial $serial `
  -DeviceLabel $DeviceLabel `
  -Iterations $Iterations `
  -Warmup $Warmup 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-Status -State "running" -Step "refresh-validator" -Serial $serial -Notes "Refreshing validation artifacts."
python $Validator --runs-dir "01-sustained-mobile-inference/logs/runs" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts" 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-Status -State "finished" -Step "done" -Serial $serial -Notes "Strict repeat completed."
