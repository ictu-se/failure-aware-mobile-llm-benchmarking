param(
  [string]$RunPrefix = "20260608-202445-MBH-N49-bai4-strict-backend-priority",
  [string]$DeviceSerial = "AWRT025806000280",
  [string]$DeviceLabel = "MBH-N49",
  [int]$Iterations = 50,
  [int]$Warmup = 3
)

$ErrorActionPreference = "Continue"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$WorkspaceRoot = Resolve-Path (Join-Path $ProjectRoot "..")
$MobileRoot = Join-Path $WorkspaceRoot "01-sustained-mobile-inference"
$Runner = Join-Path $MobileRoot "scripts\run_litert_lm_benchmark.ps1"
$Summarizer = Join-Path $MobileRoot "scripts\summarize_paper_run.py"
$RunsRoot = Join-Path $MobileRoot "logs\runs"
$StatusDir = Join-Path $ProjectRoot "artifacts\phone-strict-resume"
New-Item -ItemType Directory -Force -Path $StatusDir | Out-Null
$StatusPath = Join-Path $StatusDir "runner-current.json"
$LivePath = Join-Path $StatusDir "live-progress.md"
$LogPath = Join-Path $StatusDir "resume.log"

$Prompts = @(
  [ordered]@{ id="short"; bucket="short"; text="Explain edge AI on a phone in two short sentences." },
  [ordered]@{ id="medium"; bucket="medium"; text="Rewrite this work note into a polite and concise Vietnamese update: I finished the mobile benchmark, the NPU path is faster and cooler, and I will send the result table tonight." },
  [ordered]@{ id="long"; bucket="long"; text="You are a local mobile assistant. Summarize a benchmark session in three bullet points, mention the winning backend, describe the thermal trend, and add one limitation about plugged USB power." }
)

$Plan = @()
foreach ($p in $Prompts) { $Plan += [ordered]@{ prompt=$p; backend="CPU"; iterations=$Iterations; warmup=$Warmup } }
foreach ($p in $Prompts) { $Plan += [ordered]@{ prompt=$p; backend="GPU"; iterations=1; warmup=0 } }

$script:Completed = @()
$script:Failed = @()

function Get-Evidence {
  param([string]$RunId)
  $runDir = Join-Path $RunsRoot $RunId
  $csv = Join-Path $runDir "benchmark-output.csv"
  $summary = Join-Path $runDir "summary.json"
  $ok = 0
  $reported = @()
  $tok = ""
  $therm = ""
  if (Test-Path $csv) {
    $rows = Import-Csv $csv
    $ok = @($rows | Where-Object { $_.phase -eq "measure" -and $_.status -eq "ok" }).Count
    $reported = @($rows | Where-Object { $_.phase -eq "measure" -and $_.backend } | Select-Object -ExpandProperty backend -Unique)
  }
  if ((Test-Path $runDir) -and (-not (Test-Path $summary))) {
    python $Summarizer $runDir | Set-Content -Encoding UTF8 $summary
  }
  if (Test-Path $summary) {
    try {
      $j = Get-Content -Raw $summary | ConvertFrom-Json
      $tok = $j.benchmark.mean_tokens_per_second
      $therm = $j.thermal.thermal_peak_any_c
    } catch {}
  }
  return [ordered]@{ run_dir=$runDir; csv=(Test-Path $csv); ok_rows=$ok; reported=($reported -join ";"); tok_s=$tok; thermal_c=$therm }
}

function Write-Status {
  param([string]$State, [string]$Current="", [string]$Notes="")
  $done = $script:Completed.Count + $script:Failed.Count
  $pct = if ($Plan.Count -gt 0) { [Math]::Round(100.0 * $done / $Plan.Count, 1) } else { 0 }
  if ($State -eq "finished") { $pct = 100 }
  $obj = [ordered]@{
    run_prefix=$RunPrefix
    state=$State
    progress_percent=$pct
    completed_conditions=$script:Completed.Count
    failed_conditions=$script:Failed.Count
    total_conditions=$Plan.Count
    current=$Current
    updated_at=(Get-Date).ToString("o")
    device_serial=$DeviceSerial
    notes=$Notes
    completed=$script:Completed
    failed=$script:Failed
  }
  $obj | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $StatusPath
  $lines = @()
  $lines += "# Bài 4 strict backend resume"
  $lines += ""
  $lines += "- State: ``$State``"
  $lines += "- Progress: $pct%"
  $lines += "- Completed: $($script:Completed.Count)/$($Plan.Count)"
  $lines += "- Failed: $($script:Failed.Count)/$($Plan.Count)"
  $lines += "- Current: ``$Current``"
  $lines += "- Updated: $($obj.updated_at)"
  $lines += "- Notes: $Notes"
  $lines += ""
  $lines += "## Completed"
  foreach ($c in $script:Completed) {
    $lines += "- $($c.prompt)/$($c.backend): $($c.run_id), ok=$($c.ok_rows), reported=$($c.reported), tok/s=$($c.tok_s), thermal=$($c.thermal_c)"
  }
  $lines += ""
  $lines += "## Failed"
  foreach ($f in $script:Failed) {
    $lines += "- $($f.prompt)/$($f.backend): $($f.run_id), error=$($f.error)"
  }
  $lines | Set-Content -Encoding UTF8 $LivePath
}

Write-Status -State "running" -Current "start" -Notes "Resuming after short/CPU completed."

foreach ($cond in $Plan) {
  $p = $cond.prompt
  $backend = $cond.backend
  $runId = "$RunPrefix-$($p.id)-$($backend.ToLowerInvariant())"
  $ev = Get-Evidence -RunId $runId
  if ($ev.csv -and $ev.ok_rows -gt 0) {
    $script:Completed += [ordered]@{ prompt=$p.id; backend=$backend; run_id=$runId; ok_rows=$ev.ok_rows; reported=$ev.reported; tok_s=$ev.tok_s; thermal_c=$ev.thermal_c; reused=$true }
    Write-Status -State "running" -Current "$($p.id)/$backend" -Notes "Reused existing completed run."
    continue
  }

  Write-Status -State "running" -Current "$($p.id)/$backend" -Notes "Launching phone benchmark."
  "$(Get-Date -Format o) START $runId" | Add-Content -Encoding UTF8 $LogPath
  try {
    powershell -ExecutionPolicy Bypass -File $Runner `
      -RunId $runId `
      -DeviceLabel $DeviceLabel `
      -ModelId "gemma4-e2b" `
      -DeviceSerial $DeviceSerial `
      -PromptId "gemma_on_device_$($p.id)" `
      -PromptLengthBucket $p.bucket `
      -RequestedOutputBucket "medium" `
      -PreferredBackend $backend `
      -AppPackage "com.example.gemma_on_device" `
      -Prompt $p.text `
      -Iterations $cond.iterations `
      -Warmup $cond.warmup 2>&1 | Add-Content -Encoding UTF8 $LogPath
  } catch {
    $_.Exception.Message | Add-Content -Encoding UTF8 $LogPath
  }
  $ev = Get-Evidence -RunId $runId
  if ($ev.ok_rows -gt 0) {
    $script:Completed += [ordered]@{ prompt=$p.id; backend=$backend; run_id=$runId; ok_rows=$ev.ok_rows; reported=$ev.reported; tok_s=$ev.tok_s; thermal_c=$ev.thermal_c; reused=$false }
  } else {
    $script:Failed += [ordered]@{ prompt=$p.id; backend=$backend; run_id=$runId; error="no measured OK rows"; reported=$ev.reported }
  }
  "$(Get-Date -Format o) END $runId ok=$($ev.ok_rows) reported=$($ev.reported)" | Add-Content -Encoding UTF8 $LogPath
}

Write-Status -State "finished" -Current "done" -Notes "Resume matrix finished."
