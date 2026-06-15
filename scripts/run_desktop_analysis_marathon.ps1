param(
  [double]$Hours = 12,
  [int]$SleepSeconds = 120
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$Artifacts = Join-Path $ProjectRoot "artifacts"
$StatusDir = Join-Path $Artifacts "desktop-analysis-marathon"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null

$Start = Get-Date
$Deadline = $Start.AddHours($Hours)
$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "desktop-analysis.log"

function Write-Status {
  param([string]$State, [int]$Iteration, [string]$Step, [string]$Notes = "")
  $now = Get-Date
  $progress = [Math]::Min(100.0, [Math]::Round(100.0 * (($now - $Start).TotalSeconds) / [Math]::Max(1.0, ($Deadline - $Start).TotalSeconds), 2))
  if ($State -eq "finished") { $progress = 100 }
  $obj = [ordered]@{
    state = $State
    progress_percent_time = $progress
    iteration = $Iteration
    current_step = $Step
    started_at = $Start.ToString("o")
    deadline = $Deadline.ToString("o")
    updated_at = $now.ToString("o")
    notes = $Notes
  }
  $obj | ConvertTo-Json | Set-Content -Encoding UTF8 $StatusPath
  @(
    "# Bài 4 Desktop Analysis Marathon",
    "",
    "- State: ``$State``",
    "- Progress by time: $progress%",
    "- Iteration: $Iteration",
    "- Current step: ``$Step``",
    "- Started: $($Start.ToString("yyyy-MM-dd HH:mm:ss zzz"))",
    "- Deadline: $($Deadline.ToString("yyyy-MM-dd HH:mm:ss zzz"))",
    "- Updated: $($now.ToString("yyyy-MM-dd HH:mm:ss zzz"))",
    "- Notes: $Notes",
    "",
    "Artifacts:",
    "- ``artifacts/bootstrap-validation/bootstrap-validation-effects.md``",
    "- ``artifacts/strict-backend-evidence/strict-backend-summary.md``",
    "- ``artifacts/sensitivity/failure-sensitivity-analysis.md``",
    "- ``artifacts/logcat-failure-signatures.md``"
  ) | Set-Content -Encoding UTF8 $LivePath
}

function Run-Step {
  param([string]$Name, [scriptblock]$Block)
  "$(Get-Date -Format o) START $Name" | Add-Content -Encoding UTF8 $LogPath
  & $Block 2>&1 | Add-Content -Encoding UTF8 $LogPath
  "$(Get-Date -Format o) END $Name" | Add-Content -Encoding UTF8 $LogPath
}

$i = 0
Write-Status -State "running" -Iteration $i -Step "starting"

while ((Get-Date) -lt $Deadline) {
  $i += 1
  Write-Status -State "running" -Iteration $i -Step "validator"
  Run-Step "validator" {
    python (Join-Path $PSScriptRoot "mobile_benchmark_validator.py") `
      --runs-dir "01-sustained-mobile-inference/logs/runs" `
      --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts"
  }

  Write-Status -State "running" -Iteration $i -Step "strict-summary"
  Run-Step "strict-summary" {
    python (Join-Path $PSScriptRoot "summarize_strict_backend_evidence.py")
  }

  Write-Status -State "running" -Iteration $i -Step "sensitivity"
  Run-Step "sensitivity" {
    python (Join-Path $PSScriptRoot "failure_sensitivity_analysis.py") `
      --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" `
      --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity"
  }

  Write-Status -State "running" -Iteration $i -Step "bootstrap"
  Run-Step "bootstrap" {
    python (Join-Path $PSScriptRoot "bootstrap_validation_effects.py") `
      --boot 5000 `
      --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts/bootstrap-validation"
  }

  if (($i % 4) -eq 1) {
    Write-Status -State "running" -Iteration $i -Step "focused-logcat-mining" -Notes "Expensive step, runs every fourth iteration."
    Run-Step "focused-logcat-mining" {
      python (Join-Path $PSScriptRoot "mine_logcat_failures.py") `
        --inventory "04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv" `
        --out-dir "04-failure-aware-mobile-llm-benchmarking/artifacts"
    }
  }

  Write-Status -State "running" -Iteration $i -Step "sleep"
  Start-Sleep -Seconds $SleepSeconds
}

Write-Status -State "finished" -Iteration $i -Step "done" -Notes "Reached desktop analysis deadline."
