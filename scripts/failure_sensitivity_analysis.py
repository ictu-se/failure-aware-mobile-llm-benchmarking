#!/usr/bin/env python3
"""Sensitivity analyses for failure-aware mobile LLM benchmarking."""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean, pstdev


def read_csv(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def fnum(value):
    if value in (None, ""):
        return None
    try:
        return float(value)
    except Exception:
        return None


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", default="04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv")
    parser.add_argument("--out-dir", default="04-failure-aware-mobile-llm-benchmarking/artifacts/sensitivity")
    args = parser.parse_args()

    rows = read_csv(Path(args.inventory))
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    thresholds = [80, 85, 90, 95, 100, 105]
    threshold_rows = []
    for thr in thresholds:
        total_with_thermal = 0
        over = 0
        strict_over = 0
        mismatch_over = 0
        for row in rows:
            thermal = fnum(row.get("thermal_peak_any_c"))
            if thermal is None:
                continue
            total_with_thermal += 1
            if thermal >= thr:
                over += 1
                if row.get("strict_backend_valid") == "True":
                    strict_over += 1
                if row.get("validity_note") == "reported_backend_mismatch":
                    mismatch_over += 1
        threshold_rows.append(
            {
                "thermal_threshold_c": thr,
                "runs_with_thermal": total_with_thermal,
                "runs_at_or_above_threshold": over,
                "strict_valid_at_or_above": strict_over,
                "backend_mismatch_at_or_above": mismatch_over,
                "share_at_or_above": round(over / total_with_thermal, 6) if total_with_thermal else "",
            }
        )
    write_csv(
        out_dir / "thermal-threshold-sensitivity.csv",
        threshold_rows,
        [
            "thermal_threshold_c",
            "runs_with_thermal",
            "runs_at_or_above_threshold",
            "strict_valid_at_or_above",
            "backend_mismatch_at_or_above",
            "share_at_or_above",
        ],
    )

    grouped = defaultdict(list)
    for row in rows:
        tok = fnum(row.get("mean_tok_s"))
        if tok is None:
            continue
        key = (
            row.get("model_name") or "unknown",
            row.get("prompt") or "unknown",
            row.get("requested_backend") or "unknown",
            row.get("reported_backends") or "unknown",
            row.get("validity_note") or "unknown",
        )
        grouped[key].append(tok)

    variance_rows = []
    for key, vals in grouped.items():
        model, prompt, requested, reported, note = key
        variance_rows.append(
            {
                "model": model,
                "prompt": prompt,
                "requested_backend": requested,
                "reported_backends": reported,
                "validity_note": note,
                "runs": len(vals),
                "mean_tok_s": round(mean(vals), 6),
                "sd_tok_s": round(pstdev(vals), 6) if len(vals) > 1 else 0.0,
                "min_tok_s": round(min(vals), 6),
                "max_tok_s": round(max(vals), 6),
            }
        )
    variance_rows.sort(key=lambda r: (r["model"], r["prompt"], r["requested_backend"], r["reported_backends"]))
    write_csv(
        out_dir / "throughput-variance-by-validity.csv",
        variance_rows,
        [
            "model",
            "prompt",
            "requested_backend",
            "reported_backends",
            "validity_note",
            "runs",
            "mean_tok_s",
            "sd_tok_s",
            "min_tok_s",
            "max_tok_s",
        ],
    )

    notes = Counter(row.get("validity_note") or "unknown" for row in rows)
    requested_reported = Counter((row.get("requested_backend") or "unknown", row.get("reported_backends") or "unknown") for row in rows)
    summary = {
        "inventory": str(Path(args.inventory)),
        "runs": len(rows),
        "validity_notes": dict(sorted(notes.items())),
        "requested_reported": {f"{k[0]}->{k[1]}": v for k, v in sorted(requested_reported.items())},
        "thermal_thresholds": threshold_rows,
    }
    (out_dir / "sensitivity-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")

    lines = [
        "# Failure Sensitivity Analysis",
        "",
        f"- Inventory: `{args.inventory}`",
        f"- Runs: {len(rows)}",
        "",
        "## Thermal Thresholds",
        "",
        "| Threshold C | Runs with thermal | Runs >= threshold | Strict-valid >= | Mismatch >= | Share >= |",
        "|---:|---:|---:|---:|---:|---:|",
    ]
    for row in threshold_rows:
        lines.append(
            f"| {row['thermal_threshold_c']} | {row['runs_with_thermal']} | {row['runs_at_or_above_threshold']} | "
            f"{row['strict_valid_at_or_above']} | {row['backend_mismatch_at_or_above']} | {row['share_at_or_above']} |"
        )
    lines += ["", "## Validity Notes", "", "| Note | Runs |", "|---|---:|"]
    for key, value in sorted(notes.items()):
        lines.append(f"| {key} | {value} |")
    lines += ["", "## Requested to Reported", "", "| Requested -> Reported | Runs |", "|---|---:|"]
    for key, value in sorted(requested_reported.items()):
        lines.append(f"| {key[0]} -> {key[1]} | {value} |")
    (out_dir / "failure-sensitivity-analysis.md").write_text("\n".join(lines), encoding="utf-8")
    print(out_dir / "failure-sensitivity-analysis.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
