# 04 Failure-aware Mobile LLM Benchmarking

Goal: build a paper-grade validation study for mobile LLM benchmarking.

Manuscript files are kept local only and are intentionally ignored by git:
- `paper-springer/`
- `00_SUBMISSION/`

Core claim: on-device LLM benchmark results are incomplete unless requested backend, reported backend, completion status, empty artifacts, thermal telemetry, and power context are validated together.

Initial data sources:
- `01-sustained-mobile-inference/logs/runs`
- `01-sustained-mobile-inference/logs/mobile-*`
- `03-cross-runtime-benchmarking/artifacts/mobile-validity`
- `03-cross-runtime-benchmarking/artifacts/mobile-overnight-npu`

Primary artifacts to generate:
- mobile benchmark inventory
- validity/failure taxonomy
- naive-vs-validated ranking tables
- paper-ready CSV/Markdown summaries
