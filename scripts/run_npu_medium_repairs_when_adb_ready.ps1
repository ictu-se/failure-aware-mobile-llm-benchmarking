param(
  [string]$DeviceSerial = "AWRT025806000280",
  [string]$DeviceLabel = "MBH-N49",
  [int]$TargetValidRuns = 3,
  [int]$Iterations = 50,
  [int]$Warmup = 3,
  [int]$PollSeconds = 20,
  [int]$BatteryCooldownC = 45
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

$StatusDir = Join-Path $ProjectRoot "artifacts\phone-npu-medium-repairs"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null
$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "runner.log"
$StartedAt = Get-Date
$script:Completed = @()
$script:Failed = @()

function Get-BatteryTempC {
  try {
    $text = & $Adb shell dumpsys battery 2>$null
    $line = $text | Where-Object { $_ -match "temperature:" } | Select-Object -First 1
    if ($line -match "temperature:\s*(\d+)") {
      return [Math]::Round(([double]$Matches[1]) / 10.0, 1)
    }
  } catch {}
  return $null
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

function Write-RepairStatus {
  param(
    [string]$State,
    [string]$RunId = "",
    [string]$Notes = ""
  )
  $done = $script:Completed.Count
  $pct = if ($TargetValidRuns -gt 0) { [Math]::Round([Math]::Min(100, 100.0 * $done / $TargetValidRuns), 1) } else { 0 }
  if ($State -eq "finished") { $pct = 100 }
  $obj = [ordered]@{
    state = $State
    progress_percent = $pct
    current_run = $RunId
    target_valid_runs = $TargetValidRuns
    completed_count = $script:Completed.Count
    failed_count = $script:Failed.Count
    device_serial = $DeviceSerial
    iterations = $Iterations
    warmup = $Warmup
    battery_cooldown_c = $BatteryCooldownC
    battery_temp_c = Get-BatteryTempC
    started_at = $StartedAt.ToString("o")
    updated_at = (Get-Date).ToString("o")
    notes = $Notes
    completed = $script:Completed
    failed = $script:Failed
  }
  $obj | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $StatusPath
  $lines = @(
    "# Bài 4 NPU medium repairs",
    "",
    "- State: ``$State``",
    "- Progress: $pct%",
    "- Current run: ``$RunId``",
    "- Target valid medium/NPU runs: $TargetValidRuns",
    "- Completed: $($script:Completed.Count)",
    "- Failed: $($script:Failed.Count)",
    "- Battery temp C: $($obj.battery_temp_c)",
    "- Updated: $($obj.updated_at)",
    "- Notes: $Notes",
    "",
    "## Completed"
  )
  foreach ($item in $script:Completed) {
    $lines += "- $($item.run_id): ok_rows=$($item.ok_rows), tok_s=$($item.mean_tok_s), thermal_peak_c=$($item.thermal_peak_c)"
  }
  $lines += ""
  $lines += "## Failed"
  foreach ($item in $script:Failed) {
    $lines += "- $($item.run_id): $($item.error)"
  }
  $lines | Set-Content -Encoding UTF8 $LivePath
}

function Read-SummaryFields {
  param([string]$RunDir)
  $summaryPath = Join-Path $RunDir "summary.json"
  if (-not (Test-Path $summaryPath)) {
    return [ordered]@{ ok_rows = 0; mean_tok_s = ""; thermal_peak_c = "" }
  }
  $s = Get-Content -Raw $summaryPath | ConvertFrom-Json
  return [ordered]@{
    ok_rows = $s.benchmark.ok_measure_rows
    mean_tok_s = $s.benchmark.mean_tokens_per_second
    thermal_peak_c = $s.thermal.thermal_peak_any_c
  }
}

Write-RepairStatus -State "waiting-for-device" -Notes "Waiting for ADB device before medium/NPU repair runs."
"$(Get-Date -Format o) waiting for $DeviceSerial" | Add-Content -Encoding UTF8 $LogPath

while ($script:Completed.Count -lt $TargetValidRuns) {
  if (-not (Test-DeviceReady)) {
    Write-RepairStatus -State "waiting-for-device" -Notes "ADB device not visible."
    Start-Sleep -Seconds $PollSeconds
    continue
  }

  $temp = Get-BatteryTempC
  if ($null -ne $temp -and $temp -ge $BatteryCooldownC) {
    Write-RepairStatus -State "cooldown" -Notes "Battery temperature $temp C >= $BatteryCooldownC C; cooling down."
    Start-Sleep -Seconds 300
    continue
  }

  $runIndex = $script:Completed.Count + $script:Failed.Count + 1
  $RunId = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$DeviceLabel-bai4-npu-medium-repair-$($runIndex.ToString('00'))-npu"
  Write-RepairStatus -State "running" -RunId $RunId -Notes "Running medium/NPU repair chunk."
  "$(Get-Date -Format o) START $RunId" | Add-Content -Encoding UTF8 $LogPath

  try {
    powershell -ExecutionPolicy Bypass -File $BenchmarkRunner `
      -RunId $RunId `
      -DeviceLabel $DeviceLabel `
      -ModelId "gemma4-e2b-sm8750" `
      -DeviceSerial $DeviceSerial `
      -PromptId "medium_repair" `
      -PromptLengthBucket "medium" `
      -RequestedOutputBucket "medium" `
      -PreferredBackend "NPU" `
      -Prompt "Rewrite this benchmark note into a concise technical update: the NPU run completed, throughput stayed usable, thermal telemetry was collected, and USB power limits energy claims." `
      -Iterations $Iterations `
      -Warmup $Warmup 2>&1 | Add-Content -Encoding UTF8 $LogPath

    $RunDir = Join-Path $MobileRoot "logs\runs\$RunId"
    $Csv = Join-Path $RunDir "benchmark-output.csv"
    if (-not (Test-Path $Csv)) {
      throw "benchmark-output.csv missing"
    }

    $summaryJson = & python $Summarizer $RunDir
    [System.IO.File]::WriteAllText(
      (Join-Path $RunDir "summary.json"),
      ($summaryJson -join [Environment]::NewLine),
      [System.Text.UTF8Encoding]::new($false)
    )
    $f = Read-SummaryFields -RunDir $RunDir
    if ([int]$f.ok_rows -lt $Iterations) {
      throw "only $($f.ok_rows) ok rows"
    }
    $script:Completed += [ordered]@{
      run_id = $RunId
      run_dir = $RunDir
      ok_rows = $f.ok_rows
      mean_tok_s = $f.mean_tok_s
      thermal_peak_c = $f.thermal_peak_c
      finished_at = (Get-Date).ToString("o")
    }
  } catch {
    $script:Failed += [ordered]@{
      run_id = $RunId
      error = $_.Exception.Message
      finished_at = (Get-Date).ToString("o")
    }
    try { & $Adb shell am force-stop com.example.qnn_litertlm_gemma | Out-Null } catch {}
  }
  Write-RepairStatus -State "between-runs" -RunId $RunId -Notes "Repair attempt completed; continuing until target valid runs."
}

Write-RepairStatus -State "refreshing-artifacts" -Notes "Refreshing validation artifacts."
python $Validator --runs-dir "01-sustained-mobile-inference/logs/runs" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts" 2>&1 | Add-Content -Encoding UTF8 $LogPath
python $StrictSummary 2>&1 | Add-Content -Encoding UTF8 $LogPath
python $Sensitivity --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity" 2>&1 | Add-Content -Encoding UTF8 $LogPath

Write-RepairStatus -State "finished" -Notes "Medium/NPU repair target reached and artifacts refreshed."
