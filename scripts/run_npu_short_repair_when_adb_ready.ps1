param(
  [string]$DeviceSerial = "AWRT025806000280",
  [string]$DeviceLabel = "MBH-N49",
  [int]$Iterations = 20,
  [int]$Warmup = 3,
  [int]$PollSeconds = 30
)

$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$WorkspaceRoot = Resolve-Path (Join-Path $ProjectRoot "..")
$MobileRoot = Join-Path $WorkspaceRoot "01-sustained-mobile-inference"
$Adb = Join-Path $MobileRoot "tools\android\platform-tools\adb.exe"
$BenchmarkRunner = Join-Path $MobileRoot "scripts\run_litert_lm_benchmark.ps1"
$Summarizer = Join-Path $MobileRoot "scripts\summarize_paper_run.py"
$Validator = Join-Path $ProjectRoot "scripts\mobile_benchmark_validator.py"
$StrictSummary = Join-Path $ProjectRoot "scripts\summarize_strict_backend_evidence.py"
$Sensitivity = Join-Path $ProjectRoot "scripts\failure_sensitivity_analysis.py"

$StatusDir = Join-Path $ProjectRoot "artifacts\phone-npu-short-repair"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null
$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "runner.log"
$StartedAt = Get-Date

function Write-RepairStatus {
  param(
    [string]$State,
    [int]$Progress = 0,
    [string]$RunId = "",
    [string]$Notes = ""
  )
  $obj = [ordered]@{
    state = $State
    progress_percent = $Progress
    run_id = $RunId
    device_serial = $DeviceSerial
    iterations = $Iterations
    warmup = $Warmup
    started_at = $StartedAt.ToString("o")
    updated_at = (Get-Date).ToString("o")
    notes = $Notes
  }
  $obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $StatusPath
  @(
    "# Bài 4 NPU short repair",
    "",
    "- State: ``$State``",
    "- Progress: $Progress%",
    "- Run: ``$RunId``",
    "- Device serial: ``$DeviceSerial``",
    "- Iterations: $Iterations",
    "- Warmup: $Warmup",
    "- Updated: $($obj.updated_at)",
    "- Notes: $Notes"
  ) | Set-Content -Encoding UTF8 $LivePath
}

function Test-DeviceReady {
  if (-not (Test-Path $Adb)) {
    throw "ADB not found: $Adb"
  }
  $lines = & $Adb devices 2>$null
  foreach ($line in $lines) {
    if ($line -match "^\s*$([Regex]::Escape($DeviceSerial))\s+device\b") {
      return $true
    }
  }
  return $false
}

Write-RepairStatus -State "waiting-for-device" -Progress 0 -Notes "ADB is ready; waiting for the phone to appear."
"$(Get-Date -Format o) waiting for $DeviceSerial" | Add-Content -Encoding UTF8 $LogPath

while (-not (Test-DeviceReady)) {
  Start-Sleep -Seconds $PollSeconds
}

$RunId = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$DeviceLabel-bai4-npu-controlled-20iter-repair-short-npu"
Write-RepairStatus -State "running" -Progress 10 -RunId $RunId -Notes "Phone detected; running repair short/NPU."
"$(Get-Date -Format o) START $RunId" | Add-Content -Encoding UTF8 $LogPath

powershell -ExecutionPolicy Bypass -File $BenchmarkRunner `
  -RunId $RunId `
  -DeviceLabel $DeviceLabel `
  -ModelId "gemma4-e2b-sm8750" `
  -DeviceSerial $DeviceSerial `
  -PromptId "mobile_prompt_short" `
  -PromptLengthBucket "short" `
  -RequestedOutputBucket "medium" `
  -PreferredBackend "NPU" `
  -Prompt "Explain edge AI on a phone in two short sentences." `
  -Iterations $Iterations `
  -Warmup $Warmup 2>&1 | Add-Content -Encoding UTF8 $LogPath

$RunDir = Join-Path $MobileRoot "logs\runs\$RunId"
$Csv = Join-Path $RunDir "benchmark-output.csv"
if (-not (Test-Path $Csv)) {
  Write-RepairStatus -State "failed" -Progress 100 -RunId $RunId -Notes "Repair run ended without benchmark-output.csv."
  throw "Repair run ended without benchmark-output.csv: $Csv"
}

Write-RepairStatus -State "summarizing" -Progress 70 -RunId $RunId -Notes "CSV pulled; building summary and refreshing artifacts."
$summaryJson = & python $Summarizer $RunDir
[System.IO.File]::WriteAllText(
  (Join-Path $RunDir "summary.json"),
  ($summaryJson -join [Environment]::NewLine),
  [System.Text.UTF8Encoding]::new($false)
)

python $Validator --runs-dir "01-sustained-mobile-inference/logs/runs" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts" 2>&1 | Add-Content -Encoding UTF8 $LogPath
python $StrictSummary 2>&1 | Add-Content -Encoding UTF8 $LogPath
python $Sensitivity --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity" 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-RepairStatus -State "finished" -Progress 100 -RunId $RunId -Notes "Repair short/NPU completed and artifacts refreshed."
"$(Get-Date -Format o) END $RunId" | Add-Content -Encoding UTF8 $LogPath
