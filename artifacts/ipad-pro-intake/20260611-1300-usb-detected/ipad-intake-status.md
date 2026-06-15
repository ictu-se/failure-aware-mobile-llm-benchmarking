# iPad Pro USB intake status

Time: 2026-06-11 12:57:49 +07:00

## Detection

- Windows detects an Apple iPad over USB.
- Device class entries include `Apple Mobile Device USB Composite Device` and `Apple iPad`.
- Hardware ID observed: `USB\\VID_05AC&PID_12AB...`.

## Current limitation

- No `idevice_id` / `ideviceinfo` / iOS benchmark tooling is available in this shell.
- The Android ADB/LiteRT scripts cannot run on iPadOS.
- Therefore, no automatic iPad LLM benchmark is running yet.

## What can be done now without extra tooling

- Keep Android/offline validation running.
- Prepare iPadOS benchmark schema and manual data-entry CSV.
- Use iPad Pro later as a cross-platform extension if an iOS/Core ML app or exported benchmark CSV is available.

## Required for real iPad experiment

- An iOS benchmark app or app that exports CSV/JSON.
- Fields: prompt, runtime/backend/compute units, iteration, status, total time, tokens, tokens/s, thermal state, battery state.
- Prefer Core ML compute-unit settings if building a custom app.
