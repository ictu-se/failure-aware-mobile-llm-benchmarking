# iPad Pro experiment plan for Bài 4

## Short answer

iPad Pro can be useful, but it should be treated as a separate iPadOS/Core ML device class, not as a replacement for the Android phone experiments.

It cannot run the current Android ADB/LiteRT-LM scripts directly. Those scripts depend on:

- Android Debug Bridge (ADB)
- Android app packages such as `com.example.qnn_litertlm_gemma`
- Android paths under `/sdcard/Android/data/...`
- Android battery/thermal/logcat collectors

## Best use of iPad Pro

Use it as an additional cross-platform validation case:

> Do benchmark conclusions remain valid when the device uses iPadOS/Core ML rather than Android/LiteRT?

This would strengthen external validity, but it requires a separate measurement pipeline.

## Recommended iPad experiment tracks

### Track A: App-level manual benchmark

Use an iPad LLM app or a small custom iOS app that reports:

- model name
- runtime/backend if available
- prompt bucket
- output token count
- TTFT if available
- generation time
- tokens/s
- battery level before/after
- device thermal state if exposed

Pros: fastest to start.

Cons: less automated; backend reporting may be limited.

### Track B: Core ML / Swift benchmark

Build a small iOS benchmark app using Core ML or a local inference framework. The app should write JSON/CSV rows with:

- requested compute units: CPU only / CPU+GPU / CPU+Neural Engine if supported
- reported or configured compute units
- prompt bucket
- iteration
- status
- total time
- generated tokens
- tokens/s
- thermal state from `ProcessInfo.thermalState`
- battery state from `UIDevice`

Pros: closer to paper-grade evidence.

Cons: needs Xcode/macOS and an iOS build pipeline.

### Track C: MLX on Apple Silicon

If the iPad Pro is M-series and the toolchain permits local execution through an app or notebook-like environment, MLX-style experiments may be possible. Treat this as exploratory unless the runtime gives exportable CSV and clear backend/runtime metadata.

## What not to claim

- Do not compare Android NPU and iPad Neural Engine as if they are the same backend.
- Do not mix iPad app-level results into the Android validated ranking table.
- Do not claim energy efficiency unless the run is unplugged or battery-controlled.
- Do not claim strict backend execution unless the iPad runtime exposes or enforces compute-unit selection.

## How to use iPad data in Bài 4

Use it as an extension section:

> Cross-platform extension: Android validation protocol translated to iPadOS.

The same validation fields should be preserved:

| Field | Android source | iPadOS equivalent |
|---|---|---|
| requested backend | app intent extra / delegate flag | Core ML compute units or app setting |
| reported backend | benchmark CSV backend column | runtime metadata, if exposed |
| completion marker | `.done` file pulled by ADB | app-exported JSON/CSV completion |
| measured rows | benchmark CSV rows | app-exported CSV rows |
| thermal | `dumpsys thermalservice` | `ProcessInfo.thermalState` |
| battery | `dumpsys battery` | `UIDevice.batteryLevel/state` |
| system log | logcat | Xcode/device logs, if available |

## Priority

For the current paper, Android evidence is already enough for a strong methodology draft. iPad Pro should be the next-device extension, not a blocker.

