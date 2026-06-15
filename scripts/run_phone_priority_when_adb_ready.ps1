param(
  [int]$Hours = 10,
  [int]$PollSeconds = 20,
  [int]$Iterations = 50,
  [int]$Warmup = 3,
  [string]$DeviceLabel = "MBH-N49"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$WorkspaceRoot = Resolve-Path (Join-Path $ProjectRoot "..")
$MobileRoot = Join-Path $WorkspaceRoot "01-sustained-mobile-inference"
$Adb = Join-Path $MobileRoot "tools\android\platform-tools\adb.exe"
$StrictRunner = Join-Path $MobileRoot "scripts\run_gemma_on_device_strict_matrix.ps1"
$Validator = Join-Path $ProjectRoot "scripts\mobile_benchmark_validator.py"
$Artifacts = Join-Path $ProjectRoot "artifacts"
$StatusDir = Join-Path $Artifacts "phone-priority-runner"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null

$Start = Get-Date
$Deadline = $Start.AddHours($Hours)
$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "phone-priority.log"
$RunPrefix = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$DeviceLabel-bai4-strict-backend-priority"

function Write-Status {
  param(
    [string]$State,
    [string]$Step,
    [string]$DeviceSerial = "",
    [string]$Notes = ""
  )
  $now = Get-Date
  $total = [Math]::Max(1.0, ($Deadline - $Start).TotalSeconds)
  $progress = [Math]::Min(100.0, [Math]::Round(100.0 * (($now - $Start).TotalSeconds) / $total, 2))
  $obj = [ordered]@{
    state = $State
    progress_percent_time = $progress
    current_step = $Step
    device_serial = $DeviceSerial
    run_prefix = $RunPrefix
    started_at = $Start.ToString("o")
    deadline = $Deadline.ToString("o")
    updated_at = $now.ToString("o")
    adb_path = $Adb
    notes = $Notes
  }
  $obj | ConvertTo-Json | Set-Content -Encoding UTF8 $StatusPath
  $lines = @()
  $lines += "# Bài 4 Phone Priority Runner"
  $lines += ""
  $lines += "- State: ``$State``"
  $lines += "- Progress by time: $progress%"
  $lines += "- Current step: ``$Step``"
  $lines += "- Device serial: ``$DeviceSerial``"
  $lines += "- Run prefix: ``$RunPrefix``"
  $lines += "- Started: $($Start.ToString("yyyy-MM-dd HH:mm:ss zzz"))"
  $lines += "- Deadline: $($Deadline.ToString("yyyy-MM-dd HH:mm:ss zzz"))"
  $lines += "- Updated: $($now.ToString("yyyy-MM-dd HH:mm:ss zzz"))"
  $lines += "- Notes: $Notes"
  $lines += ""
  $lines += "If this stays in ``waiting-for-adb-device``, Windows sees the phone as MTP but ADB is not authorized/enabled."
  $lines | Set-Content -Encoding UTF8 $LivePath
}

function Get-AdbDeviceSerial {
  if (-not (Test-Path $Adb)) {
    return ""
  }
  $lines = & $Adb devices 2>$null
  foreach ($line in $lines) {
    if ($line -match '^(\S+)\s+device\b') {
      return $Matches[1]
    }
  }
  return ""
}

if (-not (Test-Path $Adb)) {
  Write-Status -State "failed" -Step "adb-missing" -Notes "adb.exe not found at $Adb"
  throw "adb.exe not found: $Adb"
}

Write-Status -State "waiting" -Step "waiting-for-adb-device" -Notes "Polling ADB until a device appears."
& $Adb start-server | Add-Content -Encoding UTF8 $LogPath

$serial = ""
while ((Get-Date) -lt $Deadline) {
  $serial = Get-AdbDeviceSerial
  if ($serial) {
    break
  }
  Write-Status -State "waiting" -Step "waiting-for-adb-device" -Notes "No ADB device yet. Phone may be connected only as MTP/USB storage."
  Start-Sleep -Seconds $PollSeconds
}

if (-not $serial) {
  Write-Status -State "failed" -Step "no-adb-device-before-deadline" -Notes "Deadline reached without an ADB-visible device."
  exit 2
}

Write-Status -State "running" -Step "strict-backend-matrix" -DeviceSerial $serial -Notes "ADB device found. Running strict CPU/GPU backend matrix first."
"$(Get-Date -Format o) DEVICE $serial" | Add-Content -Encoding UTF8 $LogPath

powershell -ExecutionPolicy Bypass -File $StrictRunner `
  -DeviceSerial $serial `
  -DeviceLabel $DeviceLabel `
  -RunPrefix $RunPrefix `
  -Iterations $Iterations `
  -Warmup $Warmup 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-Status -State "running" -Step "refresh-validator" -DeviceSerial $serial -Notes "Strict matrix finished. Refreshing Bài 4 validation artifacts."
python $Validator `
  --runs-dir "01-sustained-mobile-inference/logs/runs" `
  --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts" 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-Status -State "finished" -Step "done" -DeviceSerial $serial -Notes "Phone-priority strict backend experiment completed."
