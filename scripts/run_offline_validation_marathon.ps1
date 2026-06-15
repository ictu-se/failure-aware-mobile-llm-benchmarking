param(
  [double]$Hours = 12,
  [int]$SleepSeconds = 90
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Artifacts = Join-Path $Root "artifacts"
$Marathon = Join-Path $Artifacts "offline-validation-marathon"
New-Item -ItemType Directory -Force -Path $Marathon | Out-Null

$Start = Get-Date
$Deadline = $Start.AddHours($Hours)
$StatusPath = Join-Path $Marathon "runner-current.json"
$LivePath = Join-Path $Marathon "live-progress.md"
$LogPath = Join-Path $Marathon "marathon.log"

function Write-Status {
  param(
    [string]$State,
    [int]$Iteration,
    [string]$CurrentStep,
    [string]$Notes = ""
  )
  $now = Get-Date
  $total = [Math]::Max(1.0, ($Deadline - $Start).TotalSeconds)
  $elapsed = [Math]::Max(0.0, ($now - $Start).TotalSeconds)
  $progress = [Math]::Min(100.0, [Math]::Round(100.0 * $elapsed / $total, 2))
  $obj = [ordered]@{
    state = $State
    progress_percent_time = $progress
    iteration = $Iteration
    current_step = $CurrentStep
    started_at = $Start.ToString("o")
    deadline = $Deadline.ToString("o")
    updated_at = $now.ToString("o")
    artifacts_dir = $Artifacts
    notes = $Notes
  }
  $obj | ConvertTo-Json | Set-Content -Encoding UTF8 $StatusPath
  $lines = @()
  $lines += "# Bài 4 Offline Validation Marathon"
  $lines += ""
  $lines += "- State: ``$State``"
  $lines += "- Progress by time: $progress%"
  $lines += "- Iteration: $Iteration"
  $lines += "- Current step: ``$CurrentStep``"
  $lines += "- Started: $($Start.ToString("yyyy-MM-dd HH:mm:ss zzz"))"
  $lines += "- Deadline: $($Deadline.ToString("yyyy-MM-dd HH:mm:ss zzz"))"
  $lines += "- Updated: $($now.ToString("yyyy-MM-dd HH:mm:ss zzz"))"
  if ($Notes) { $lines += "- Notes: $Notes" }
  $lines += ""
  $lines += "Latest artifacts:"
  $lines += "- ``04-failure-aware-mobile-llm-benchmarking/artifacts/mobile-benchmark-validation-report.md``"
  $lines += "- ``04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-validation-report.md``"
  $lines += "- ``04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity/failure-sensitivity-analysis.md``"
  $lines += "- ``04-failure-aware-mobile-llm-benchmarking/artifacts/logcat-failure-signatures.md``"
  $lines | Set-Content -Encoding UTF8 $LivePath
}

function Run-Step {
  param(
    [string]$Name,
    [scriptblock]$Block
  )
  "$(Get-Date -Format o) START $Name" | Add-Content -Encoding UTF8 $LogPath
  & $Block 2>&1 | Add-Content -Encoding UTF8 $LogPath
  "$(Get-Date -Format o) END $Name" | Add-Content -Encoding UTF8 $LogPath
}

$Iteration = 0
Write-Status -State "running" -Iteration $Iteration -CurrentStep "starting"

while ((Get-Date) -lt $Deadline) {
  $Iteration += 1
  Write-Status -State "running" -Iteration $Iteration -CurrentStep "validator"
  Run-Step "validator" {
    python (Join-Path $PSScriptRoot "mobile_benchmark_validator.py") `
      --runs-dir "01-sustained-mobile-inference/logs/runs" `
      --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts"
  }

  Write-Status -State "running" -Iteration $Iteration -CurrentStep "sensitivity"
  Run-Step "sensitivity" {
    python (Join-Path $PSScriptRoot "failure_sensitivity_analysis.py") `
      --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" `
      --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity"
  }

  if (($Iteration % 3) -eq 1) {
    Write-Status -State "running" -Iteration $Iteration -CurrentStep "focused-logcat-mining" -Notes "Logcat mining is expensive, so it runs every third iteration."
    Run-Step "focused-logcat-mining" {
      python (Join-Path $PSScriptRoot "mine_logcat_failures.py") `
        --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" `
        --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts"
    }
  }

  Write-Status -State "running" -Iteration $Iteration -CurrentStep "sleep" -Notes "Sleeping before next validation pass."
  Start-Sleep -Seconds $SleepSeconds
}

Write-Status -State "finished" -Iteration $Iteration -CurrentStep "done" -Notes "Reached requested marathon duration."
