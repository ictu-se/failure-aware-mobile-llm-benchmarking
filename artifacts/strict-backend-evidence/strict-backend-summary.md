# Strict Backend Evidence Summary

- Runs included: 26
- Strict-valid runs: 13
- CPU measured OK rows: 605
- GPU measured OK rows: 0

| Prompt | Requested | Runs | Successful | Failed | OK rows | Reported | Mean tok/s | SD tok/s | Max thermal C |
|---|---|---:|---:|---:|---:|---|---:|---:|---:|
| long | CPU | 4 | 4 | 0 | 200 | CPU | 18.2551 | 1.1851 | 78.4 |
| long | GPU | 4 | 0 | 4 | 0 |  |  |  | 53.6 |
| medium | CPU | 4 | 4 | 0 | 200 | CPU | 13.2038 | 0.6405 | 85.3 |
| medium | GPU | 4 | 0 | 4 | 0 |  |  |  | 54.0 |
| short | CPU | 5 | 5 | 0 | 205 | CPU | 22.9304 | 4.0664 | 79.9 |
| short | GPU | 5 | 0 | 5 | 0 |  |  |  | 57.5 |

Interpretation: strict CPU execution is repeatable over short, medium, and long prompts. Strict GPU requests did not produce measured OK rows for this app/model/device combination, so GPU rows are reported as failure evidence rather than omitted.
