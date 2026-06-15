# Failure Sensitivity Analysis

- Inventory: `04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv`
- Runs: 123

## Thermal Thresholds

| Threshold C | Runs with thermal | Runs >= threshold | Strict-valid >= | Mismatch >= | Share >= |
|---:|---:|---:|---:|---:|---:|
| 80 | 123 | 89 | 69 | 20 | 0.723577 |
| 85 | 123 | 75 | 55 | 20 | 0.609756 |
| 90 | 123 | 58 | 41 | 17 | 0.471545 |
| 95 | 123 | 39 | 27 | 12 | 0.317073 |
| 100 | 123 | 26 | 19 | 7 | 0.211382 |
| 105 | 123 | 5 | 5 | 0 | 0.04065 |

## Validity Notes

| Note | Runs |
|---|---:|
| ok | 20 |
| ok_high_thermal | 19 |
| ok_usb_powered | 61 |
| reported_backend_mismatch | 23 |

## Requested to Reported

| Requested -> Reported | Runs |
|---|---:|
| CPU -> NPU | 14 |
| GPU -> NPU | 9 |
| NPU -> NPU | 100 |