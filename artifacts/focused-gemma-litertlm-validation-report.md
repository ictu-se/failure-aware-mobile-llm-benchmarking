# Focused Gemma LiteRT-LM Benchmark Validation Report

## Inventory

- Total run directories scanned: 123
- Strict-valid runs: 100
- Backend-mismatch runs: 23
- Empty/partial/null runs: 0
- Strict-valid but high-thermal runs: 19

## Run Families

| Family | Runs |
|---|---:|
| backend_replication | 3 |
| endurance | 7 |
| other | 60 |
| overnight_chunked | 15 |
| prompt_matrix | 23 |
| prompt_replication | 3 |
| prompt_resume | 5 |
| repair | 3 |
| smoke | 4 |

## Failure Taxonomy

| Validity note | Runs |
|---|---:|
| ok | 20 |
| ok_high_thermal | 19 |
| ok_usb_powered | 61 |
| reported_backend_mismatch | 23 |

## Naive Ranking

Naive ranking uses every run with throughput, even if requested and reported backends differ.

| Model | Prompt | Requested backend | Runs | OK rows | Mean tok/s | Max thermal C |
|---|---|---|---:|---:|---:|---:|
| gemma4-e2b-sm8750 | long | NPU | 29 | 565 | 43.914655 | 104.6 |
| gemma4-e2b-sm8750 | long | CPU | 3 | 70 | 38.721033 | 103.1 |
| gemma4-e2b-sm8750 | long | GPU | 2 | 50 | 37.8785 | 102.3 |
| gemma4-e2b-sm8750 | medium | NPU | 29 | 652 | 39.96761 | 105.4 |
| gemma4-e2b-sm8750 | medium | CPU | 2 | 50 | 28.4465 | 98.1 |
| gemma4-e2b-sm8750 | short | NPU | 36 | 817 | 43.983008 | 102.3 |
| gemma4-e2b-sm8750 | short | CPU | 9 | 174 | 43.289522 | 102.7 |
| gemma4-e2b-sm8750 | short | GPU | 7 | 162 | 42.826486 | 103.5 |
| gemma4-e2b-sm8750 | unknown | NPU | 6 | 27 | 53.69395 | 82.6 |

## Validated Ranking

Validated ranking keeps only runs whose requested backend matches the benchmark-reported backend and that produced measured rows.

| Model | Prompt | Backend | Runs | OK rows | Mean tok/s | Max thermal C |
|---|---|---|---:|---:|---:|---:|
| gemma4-e2b-sm8750 | long | NPU | 29 | 565 | 43.914655 | 104.6 |
| gemma4-e2b-sm8750 | medium | NPU | 29 | 652 | 39.96761 | 105.4 |
| gemma4-e2b-sm8750 | short | NPU | 36 | 817 | 43.983008 | 102.3 |
| gemma4-e2b-sm8750 | unknown | NPU | 6 | 27 | 53.69395 | 82.6 |

## Paper Claim

The ranking changes after validation. Requested CPU/GPU rows can look competitive in a naive throughput table, but many report NPU execution in the benchmark CSV. A paper-grade mobile LLM benchmark therefore needs backend validation, completion validation, null-artifact handling, thermal context, and power-context disclosure.
