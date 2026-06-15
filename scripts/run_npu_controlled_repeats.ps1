param(
  [string]$DeviceSerial = "AWRT025806000280",
  [string]$DeviceLabel = "MBH-N49",
  [int]$Repeats = 2,
  [int]$Iterations = 20,
  [int]$Warmup = 3
)

$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$WorkspaceRoot = Resolve-Path (Join-Path $ProjectRoot "..")
$MobileRoot = Join-Path $WorkspaceRoot "01-sustained-mobile-inference"
$MatrixRunner = Join-Path $MobileRoot "scripts\run_mobile_prompt_backend_matrix.ps1"
$Validator = Join-Path $ProjectRoot "scripts\mobile_benchmark_validator.py"
$StrictSummary = Join-Path $ProjectRoot "scripts\summarize_strict_backend_evidence.py"
$Sensitivity = Join-Path $ProjectRoot "scripts\failure_sensitivity_analysis.py"
$StatusDir = Join-Path $ProjectRoot "artifacts\phone-npu-controlled-repeats"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null

$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "runner.log"
$script:Completed = @()
$script:Failed = @()
$script:StartedAt = Get-Date

function Write-Status {
  param([string]$State, [int]$RepeatIndex = 0, [string]$CurrentPrefix = "", [string]$Notes = "")
  $done = $script:Completed.Count + $script:Failed.Count
  $pct = if ($Repeats -gt 0) { [Math]::Round(100.0 * $done / $Repeats, 1) } else { 0 }
  if ($State -eq "finished") { $pct = 100 }
  $obj = [ordered]@{
    state = $State
    progress_percent = $pct
    repeat_index = $RepeatIndex
    repeats = $Repeats
    current_prefix = $CurrentPrefix
    iterations = $Iterations
    warmup = $Warmup
    device_serial = $DeviceSerial
    started_at = $script:StartedAt.ToString("o")
    updated_at = (Get-Date).ToString("o")
    notes = $Notes
    completed = $script:Completed
    failed = $script:Failed
  }
  $obj | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $StatusPath
  $lines = @(
    "# Bài 4 NPU controlled repeats",
    "",
    "- State: ``$State``",
    "- Progress: $pct%",
    "- Repeat: $RepeatIndex/$Repeats",
    "- Current prefix: ``$CurrentPrefix``",
    "- Iterations per prompt: $Iterations",
    "- Warmup: $Warmup",
    "- Updated: $($obj.updated_at)",
    "- Notes: $Notes",
    "",
    "## Completed",
    ""
  )
  foreach ($r in $script:Completed) {
    $lines += "- repeat $($r.repeat): ``$($r.prefix)``"
  }
  $lines += ""
  $lines += "## Failed"
  foreach ($r in $script:Failed) {
    $lines += "- repeat $($r.repeat): ``$($r.prefix)`` - $($r.error)"
  }
  $lines | Set-Content -Encoding UTF8 $LivePath
}

Write-Status -State "running" -Notes "Starting NPU controlled repeats."

for ($i = 1; $i -le $Repeats; $i++) {
  $prefix = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$DeviceLabel-bai4-npu-controlled-20iter-r$i"
  Write-Status -State "running" -RepeatIndex $i -CurrentPrefix $prefix -Notes "Running repeat $i."
  "$(Get-Date -Format o) START repeat=$i prefix=$prefix" | Add-Content -Encoding UTF8 $LogPath
  try {
    powershell -ExecutionPolicy Bypass -File $MatrixRunner `
      -DeviceSerial $DeviceSerial `
      -DeviceLabel $DeviceLabel `
      -ModelId "gemma4-e2b-sm8750" `
      -Backends "NPU" `
      -RunPrefix $prefix `
      -Iterations $Iterations `
      -Warmup $Warmup 2>&1 | Add-Content -Encoding UTF8 $LogPath
    $script:Completed += [ordered]@{
      repeat = $i
      prefix = $prefix
      finished_at = (Get-Date).ToString("o")
    }
  } catch {
    $script:Failed += [ordered]@{
      repeat = $i
      prefix = $prefix
      error = $_.Exception.Message
      failed_at = (Get-Date).ToString("o")
    }
  }
  "$(Get-Date -Format o) END repeat=$i prefix=$prefix" | Add-Content -Encoding UTF8 $LogPath
}

Write-Status -State "running" -RepeatIndex $Repeats -Notes "Refreshing validation artifacts."
python $Validator --runs-dir "01-sustained-mobile-inference/logs/runs" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts" 2>&1 | Add-Content -Encoding UTF8 $LogPath
python $StrictSummary 2>&1 | Add-Content -Encoding UTF8 $LogPath
python $Sensitivity --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity" 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-Status -State "finished" -RepeatIndex $Repeats -Notes "NPU controlled repeats finished and artifacts refreshed."
