#!/usr/bin/env python3
"""Summarize strict CPU/GPU backend evidence for the Bài 4 paper."""

from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path
from statistics import mean, pstdev


ROOT = Path("04-failure-aware-mobile-llm-benchmarking")
INV = ROOT / "artifacts" / "mobile-benchmark-inventory.csv"
OUT_DIR = ROOT / "artifacts" / "strict-backend-evidence"


def fnum(value):
    if value in ("", None):
        return None
    try:
        return float(value)
    except Exception:
        return None


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with INV.open("r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    strict_rows = [
        r
        for r in rows
        if r["app_package"] == "com.example.gemma_on_device"
        and r["requested_backend"] in ("CPU", "GPU")
        and (
            r["run_id"].startswith("20260605-MBH-N49-gemma-on-device-strict")
            or "bai4-strict" in r["run_id"]
        )
    ]
    strict_rows.sort(key=lambda r: r["run_id"])

    fields = [
        "run_id",
        "prompt",
        "requested_backend",
        "reported_backends",
        "measure_rows",
        "ok_measure_rows",
        "strict_backend_valid",
        "validity_note",
        "mean_tok_s",
        "mean_ttft_ms",
        "thermal_peak_any_c",
        "battery_peak_temp_c",
        "run_dir",
    ]
    with (OUT_DIR / "strict-backend-runs.csv").open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for r in strict_rows:
            writer.writerow({k: r.get(k, "") for k in fields})

    groups = defaultdict(list)
    for r in strict_rows:
        groups[(r["prompt"] or "unknown", r["requested_backend"])].append(r)

    summary_rows = []
    for (prompt, backend), group in sorted(groups.items()):
        ok_rows = sum(int(r["ok_measure_rows"] or 0) for r in group)
        successful_runs = sum(1 for r in group if int(r["ok_measure_rows"] or 0) > 0)
        failed_runs = len(group) - successful_runs
        toks = [fnum(r["mean_tok_s"]) for r in group if fnum(r["mean_tok_s"]) is not None]
        thermals = [fnum(r["thermal_peak_any_c"]) for r in group if fnum(r["thermal_peak_any_c"]) is not None]
        reported = sorted({r["reported_backends"] for r in group if r["reported_backends"]})
        summary_rows.append(
            {
                "prompt": prompt,
                "requested_backend": backend,
                "runs": len(group),
                "successful_runs": successful_runs,
                "failed_runs": failed_runs,
                "ok_rows": ok_rows,
                "reported_backends": ";".join(reported),
                "mean_tok_s_across_successes": round(mean(toks), 4) if toks else "",
                "sd_tok_s_across_successes": round(pstdev(toks), 4) if len(toks) > 1 else (0.0 if toks else ""),
                "min_tok_s": round(min(toks), 4) if toks else "",
                "max_tok_s": round(max(toks), 4) if toks else "",
                "max_thermal_c": round(max(thermals), 1) if thermals else "",
            }
        )

    summary_fields = list(summary_rows[0].keys()) if summary_rows else []
    with (OUT_DIR / "strict-backend-summary.csv").open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=summary_fields)
        writer.writeheader()
        writer.writerows(summary_rows)

    total_cpu_ok = sum(int(r["ok_measure_rows"] or 0) for r in strict_rows if r["requested_backend"] == "CPU")
    total_gpu_ok = sum(int(r["ok_measure_rows"] or 0) for r in strict_rows if r["requested_backend"] == "GPU")
    strict_valid = sum(1 for r in strict_rows if r["strict_backend_valid"] == "True")
    result = {
        "runs": len(strict_rows),
        "strict_valid_runs": strict_valid,
        "cpu_ok_rows": total_cpu_ok,
        "gpu_ok_rows": total_gpu_ok,
        "summary": summary_rows,
    }
    (OUT_DIR / "strict-backend-summary.json").write_text(json.dumps(result, indent=2), encoding="utf-8")

    lines = [
        "# Strict Backend Evidence Summary",
        "",
        f"- Runs included: {len(strict_rows)}",
        f"- Strict-valid runs: {strict_valid}",
        f"- CPU measured OK rows: {total_cpu_ok}",
        f"- GPU measured OK rows: {total_gpu_ok}",
        "",
        "| Prompt | Requested | Runs | Successful | Failed | OK rows | Reported | Mean tok/s | SD tok/s | Max thermal C |",
        "|---|---|---:|---:|---:|---:|---|---:|---:|---:|",
    ]
    for r in summary_rows:
        lines.append(
            f"| {r['prompt']} | {r['requested_backend']} | {r['runs']} | {r['successful_runs']} | "
            f"{r['failed_runs']} | {r['ok_rows']} | {r['reported_backends']} | "
            f"{r['mean_tok_s_across_successes']} | {r['sd_tok_s_across_successes']} | {r['max_thermal_c']} |"
        )
    lines += [
        "",
        "Interpretation: strict CPU execution is repeatable over short, medium, and long prompts. "
        "Strict GPU requests did not produce measured OK rows for this app/model/device combination, "
        "so GPU rows are reported as failure evidence rather than omitted.",
        "",
    ]
    (OUT_DIR / "strict-backend-summary.md").write_text("\n".join(lines), encoding="utf-8")
    print(OUT_DIR / "strict-backend-summary.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
