# Bài 4 Experiment Status

Updated: 2026-06-08 15:50:32 +07:00

## What has been run

- Created project folder `04-failure-aware-mobile-llm-benchmarking`.
- Built `scripts/mobile_benchmark_validator.py`.
- Scanned all mobile run directories under `01-sustained-mobile-inference/logs/runs`.
- Generated full mobile inventory, failure taxonomy, naive ranking, validated ranking.
- Generated a focused Gemma LiteRT-LM subset to avoid mixing unrelated FastVLM/tiny-GPT/smoke workloads.

## Full inventory result
- Total scanned runs: 268
- Strict-valid runs: 175
- Backend mismatch runs: 33
- Partial/null/empty runs: 28

## Focused Gemma LiteRT-LM result
- Focused runs: 102
- Strict-valid focused runs: 79
- Backend mismatch focused runs: 23
- High-thermal strict-valid runs: 12

## Requested-to-reported backend confusion matrix

| Requested | Reported | Runs | OK rows |
|---|---|---:|---:|
| CPU | NPU | 14 | 294 |
| GPU | NPU | 9 | 212 |
| NPU | NPU | 79 | 1281 |

## Current paper claim

Naive requested-backend rankings overstate CPU/GPU evidence. In the focused Gemma LiteRT-LM subset, CPU/GPU requested runs can have usable throughput, but the validated ranking retains only NPU rows because CPU/GPU requested rows report a different backend. This gives Bài 4 a clean methods contribution: mobile LLM benchmarks need backend validation, artifact validation, thermal context, and power-context disclosure.

## Next useful experiments

- If the phone is available: run strict CPU/NPU/GPU enforcement again with controlled prompts, making failures first-class rows.
- If no phone is available: continue with offline analysis by adding logcat failure mining and thermal-threshold survival curves.


## Logcat mining result

- Focused Gemma LiteRT-LM logcat files scanned: 102 runs.
- Aggregate hits in focused subset:
  - delegate/backend related: 94,534
  - thermal related: 22,352
  - memory/OOM related pattern hits: 8,391
  - timeout/ANR related: 2,883
  - exception related: 1,265
- Artifact files: `logcat-failure-signatures.csv` and `logcat-failure-signatures.md`.
- Caution: these are pattern hits, not manually verified root causes. Use them as supporting telemetry/failure-context evidence, not as final causal labels.
