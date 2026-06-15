# Mobile Benchmark Validation Report

## Inventory

- Total run directories scanned: 316
- Strict-valid runs: 205
- Backend-mismatch runs: 33
- Empty/partial/null runs: 37
- Strict-valid but high-thermal runs: 19

## Run Families

| Family | Runs |
|---|---:|
| backend_replication | 3 |
| endurance | 7 |
| other | 205 |
| overnight_chunked | 23 |
| prompt_matrix | 30 |
| prompt_replication | 4 |
| prompt_resume | 6 |
| repair | 5 |
| smoke | 13 |
| strict_backend | 20 |

## Failure Taxonomy

| Validity note | Runs |
|---|---:|
| all_measurements_failed | 26 |
| backend_unknown | 15 |
| ok | 64 |
| ok_high_thermal | 19 |
| ok_usb_powered | 122 |
| partial_or_missing_completion | 37 |
| reported_backend_mismatch | 33 |

## Naive Ranking

Naive ranking uses every run with throughput, even if requested and reported backends differ.

| Model | Prompt | Requested backend | Runs | OK rows | Mean tok/s | Max thermal C |
|---|---|---|---:|---:|---:|---:|
| fastvlm-0.5b-sm8750 | long | NPU | 15 | 45 | 98.531027 | 72.9 |
| fastvlm-0.5b-sm8750 | medium | NPU | 15 | 45 | 90.300633 | 66.8 |
| fastvlm-0.5b-sm8750 | short | NPU | 19 | 57 | 94.846137 | 73.7 |
| fastvlm-0.5b-sm8750 | unknown | NPU | 9 | 42 | 87.480367 | 61.0 |
| gemma4-e2b | long | GPU | 3 | 9 | 21.897467 | 79.9 |
| gemma4-e2b | long | CPU | 7 | 209 | 20.856571 | 80.7 |
| gemma4-e2b | medium | GPU | 3 | 9 | 30.443267 | 74.9 |
| gemma4-e2b | medium | CPU | 7 | 209 | 20.449343 | 85.3 |
| gemma4-e2b | short | GPU | 4 | 11 | 30.7992 | 65.6 |
| gemma4-e2b | short | CPU | 9 | 215 | 26.895456 | 83.0 |
| gemma4-e2b-sm8750 | long | NPU | 29 | 565 | 43.914655 | 104.6 |
| gemma4-e2b-sm8750 | long | CPU | 3 | 70 | 38.721033 | 103.1 |
| gemma4-e2b-sm8750 | long | GPU | 2 | 50 | 37.8785 | 102.3 |
| gemma4-e2b-sm8750 | medium | NPU | 29 | 652 | 39.96761 | 105.4 |
| gemma4-e2b-sm8750 | medium | CPU | 2 | 50 | 28.4465 | 98.1 |
| gemma4-e2b-sm8750 | short | NPU | 36 | 817 | 43.983008 | 102.3 |
| gemma4-e2b-sm8750 | short | CPU | 9 | 174 | 43.289522 | 102.7 |
| gemma4-e2b-sm8750 | short | GPU | 7 | 162 | 42.826486 | 103.5 |
| gemma4-e2b-sm8750 | unknown | NPU | 6 | 27 | 53.69395 | 82.6 |
| phi3-mini-4k-instruct-onnx-cpu-int4 | long | CPU | 7 | 21 | 15.826167 |  |
| phi3-mini-4k-instruct-onnx-cpu-int4 | medium | CPU | 7 | 21 | 16.672386 |  |
| phi3-mini-4k-instruct-onnx-cpu-int4 | short | CPU | 9 | 27 | 6.065474 |  |
| tiny-random-gpt2-fp32 | short | CPU | 3 | 3 | 6274.531078 |  |

## Validated Ranking

Validated ranking keeps only runs whose requested backend matches the benchmark-reported backend and that produced measured rows.

| Model | Prompt | Backend | Runs | OK rows | Mean tok/s | Max thermal C |
|---|---|---|---:|---:|---:|---:|
| fastvlm-0.5b-sm8750 | long | NPU | 15 | 45 | 98.531027 | 72.9 |
| fastvlm-0.5b-sm8750 | medium | NPU | 15 | 45 | 90.300633 | 66.8 |
| fastvlm-0.5b-sm8750 | short | NPU | 19 | 57 | 94.846137 | 73.7 |
| fastvlm-0.5b-sm8750 | unknown | NPU | 9 | 42 | 87.480367 | 61.0 |
| gemma4-e2b | long | CPU | 7 | 209 | 20.856571 | 80.7 |
| gemma4-e2b | medium | CPU | 7 | 209 | 20.449343 | 85.3 |
| gemma4-e2b | short | CPU | 9 | 215 | 26.895456 | 83.0 |
| gemma4-e2b-sm8750 | long | NPU | 29 | 565 | 43.914655 | 104.6 |
| gemma4-e2b-sm8750 | medium | NPU | 29 | 652 | 39.96761 | 105.4 |
| gemma4-e2b-sm8750 | short | NPU | 36 | 817 | 43.983008 | 102.3 |
| gemma4-e2b-sm8750 | unknown | NPU | 6 | 27 | 53.69395 | 82.6 |
| phi3-mini-4k-instruct-onnx-cpu-int4 | long | CPU | 7 | 21 | 15.826167 |  |
| phi3-mini-4k-instruct-onnx-cpu-int4 | medium | CPU | 7 | 21 | 16.672386 |  |
| phi3-mini-4k-instruct-onnx-cpu-int4 | short | CPU | 9 | 27 | 6.065474 |  |
| tiny-random-gpt2-fp32 | short | CPU | 1 | 3 | 14529.2599 |  |

## Paper Claim

The ranking changes after validation. Requested CPU/GPU rows can look competitive in a naive throughput table, but many report NPU execution in the benchmark CSV. A paper-grade mobile LLM benchmark therefore needs backend validation, completion validation, null-artifact handling, thermal context, and power-context disclosure.
