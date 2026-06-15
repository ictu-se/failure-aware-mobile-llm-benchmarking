#!/usr/bin/env python3
"""Validate mobile LLM benchmark artifacts.

The script scans run directories produced by the mobile experiments and emits
paper-ready artifacts for failure-aware benchmark analysis.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean, pstdev


BACKENDS = ("CPU", "GPU", "NPU")


def read_json(path: Path) -> dict:
    if not path.exists() or path.stat().st_size == 0:
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception:
        return {}


def read_csv_rows(path: Path) -> list[dict]:
    if not path.exists() or path.stat().st_size == 0:
        return []
    try:
        with path.open("r", encoding="utf-8-sig", newline="") as f:
            return list(csv.DictReader(f))
    except Exception:
        return []


def parse_backend(value: str | None) -> str:
    if not value:
        return ""
    value = value.upper()
    for backend in BACKENDS:
        if backend in value:
            return backend
    return ""


def infer_requested_backend(run_id: str, metadata: dict) -> str:
    explicit = parse_backend(str(metadata.get("delegate", "")))
    if explicit:
        return explicit
    low = run_id.lower()
    for backend in BACKENDS:
        if f"-{backend.lower()}" in low or f"_{backend.lower()}" in low:
            return backend
    return ""


def infer_kind(run_id: str, metadata: dict) -> str:
    prompt_id = str(metadata.get("prompt_id", "")).lower()
    low = run_id.lower()
    if "overnight" in low or "chunked" in low:
        return "overnight_chunked"
    if "strict" in low or "gemma-on-device" in low:
        return "strict_backend"
    if "prompt-backend-resume" in low:
        return "prompt_resume"
    if "prompt-backend-replication" in low:
        return "prompt_replication"
    if "prompt-backend" in low or "prompt" in prompt_id:
        return "prompt_matrix"
    if "backend-replication" in low:
        return "backend_replication"
    if "endurance" in low or "backend_matrix" in prompt_id:
        return "endurance"
    if "repair" in low:
        return "repair"
    if "smoke" in low:
        return "smoke"
    return "other"


def as_float(value) -> float | None:
    if value is None or value == "":
        return None
    try:
        v = float(value)
    except Exception:
        return None
    if math.isnan(v) or math.isinf(v):
        return None
    return v


def summarize_timeseries(path: Path, preferred_columns: tuple[str, ...]) -> float | None:
    rows = read_csv_rows(path)
    values: list[float] = []
    for row in rows:
        for col in preferred_columns:
            v = as_float(row.get(col))
            if v is not None:
                values.append(v)
                break
    return max(values) if values else None


def classify_failure(
    done_marker: bool,
    has_summary: bool,
    measure_rows: int,
    ok_rows: int,
    requested: str,
    reported: str,
    charging: bool,
    thermal_peak: float | None,
) -> tuple[bool, str]:
    if measure_rows == 0:
        if not done_marker and not has_summary:
            return False, "partial_or_missing_completion"
        return False, "empty_or_null_measurement"
    if ok_rows == 0:
        return False, "all_measurements_failed"
    if requested and reported and requested != reported:
        return False, "reported_backend_mismatch"
    if not requested or not reported:
        return False, "backend_unknown"
    if thermal_peak is not None and thermal_peak >= 100.0:
        return True, "ok_high_thermal"
    if charging:
        return True, "ok_usb_powered"
    return True, "ok"


def validate_run(run_dir: Path) -> dict:
    run_id = run_dir.name
    metadata_doc = read_json(run_dir / "run-metadata.json")
    summary_doc = read_json(run_dir / "summary.json")
    metadata = metadata_doc or summary_doc.get("metadata", {})
    benchmark = summary_doc.get("benchmark", {})
    battery = summary_doc.get("battery", {})
    thermal = summary_doc.get("thermal", {})
    csv_rows = read_csv_rows(run_dir / "benchmark-output.csv")
    measure_csv = [r for r in csv_rows if str(r.get("phase", "")).lower() == "measure"]
    if not measure_csv and csv_rows:
        measure_csv = csv_rows

    measure_rows = int(benchmark.get("measure_rows") or len(measure_csv) or 0)
    ok_rows = int(benchmark.get("ok_measure_rows") or 0)
    if measure_csv and not ok_rows:
        ok_rows = sum(1 for r in measure_csv if str(r.get("status", "")).lower() in ("ok", "success", ""))

    requested = infer_requested_backend(run_id, metadata)
    reported_values = sorted(
        {
            parse_backend(row.get("backend"))
            for row in measure_csv
            if parse_backend(row.get("backend"))
        }
    )
    reported = "|".join(reported_values)
    if "|" in reported:
        reported_for_validity = ""
    else:
        reported_for_validity = reported

    tok_values = [as_float(r.get("tokens_per_second")) for r in measure_csv]
    tok_values = [v for v in tok_values if v is not None]
    ttft_values = [as_float(r.get("ttft_ms")) for r in measure_csv]
    ttft_values = [v for v in ttft_values if v is not None]

    mean_tok_s = as_float(benchmark.get("mean_tokens_per_second"))
    if mean_tok_s is None and tok_values:
        mean_tok_s = mean(tok_values)
    mean_ttft_ms = as_float(benchmark.get("mean_ttft_ms"))
    if mean_ttft_ms is None and ttft_values:
        mean_ttft_ms = mean(ttft_values)

    done_marker = any((run_dir / "_poll").glob("*.done")) or any(run_dir.glob("*.done"))
    has_summary = bool(summary_doc) and bool(benchmark)
    charging = bool(battery.get("charging_contaminated", False))
    battery_peak = as_float(battery.get("battery_peak_temp_c"))
    thermal_peak = as_float(thermal.get("thermal_peak_any_c"))
    if thermal_peak is None:
        thermal_peak = summarize_timeseries(run_dir / "thermal-timeseries.csv", ("temperature_c", "temp_c", "value_c"))

    strict_valid, validity_note = classify_failure(
        done_marker=done_marker,
        has_summary=has_summary,
        measure_rows=measure_rows,
        ok_rows=ok_rows,
        requested=requested,
        reported=reported_for_validity,
        charging=charging,
        thermal_peak=thermal_peak,
    )

    return {
        "run_id": run_id,
        "kind": infer_kind(run_id, metadata),
        "device_label": metadata.get("device_label", ""),
        "runtime": metadata.get("runtime", ""),
        "model_name": metadata.get("model_name", ""),
        "app_package": metadata.get("app_package", ""),
        "prompt": metadata.get("prompt_length_bucket", ""),
        "requested_backend": requested,
        "reported_backends": reported,
        "done_marker": done_marker,
        "has_summary": has_summary,
        "measure_rows": measure_rows,
        "ok_measure_rows": ok_rows,
        "strict_backend_valid": strict_valid,
        "validity_note": validity_note,
        "mean_tok_s": round(mean_tok_s, 6) if mean_tok_s is not None else "",
        "mean_ttft_ms": round(mean_ttft_ms, 6) if mean_ttft_ms is not None else "",
        "battery_peak_temp_c": battery_peak if battery_peak is not None else "",
        "thermal_peak_any_c": thermal_peak if thermal_peak is not None else "",
        "charging_contaminated": charging,
        "run_dir": str(run_dir),
    }


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def ranking(rows: list[dict], strict_only: bool) -> list[dict]:
    groups: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    for row in rows:
        if strict_only and not row["strict_backend_valid"]:
            continue
        if row["mean_tok_s"] == "":
            continue
        model = row["model_name"] or row["app_package"] or "unknown"
        key = (model, row["prompt"] or "unknown", row["requested_backend"] or "unknown")
        groups[key].append(row)
    out = []
    for (model, prompt, backend), group in groups.items():
        vals = [float(r["mean_tok_s"]) for r in group]
        ok = sum(int(r["ok_measure_rows"]) for r in group)
        out.append(
            {
                "model": model,
                "prompt": prompt,
                "backend": backend,
                "strict_only": strict_only,
                "runs": len(group),
                "ok_rows": ok,
                "mean_of_run_means_tok_s": round(mean(vals), 6),
                "sd_of_run_means_tok_s": round(pstdev(vals), 6) if len(vals) > 1 else 0.0,
                "max_thermal_c": max(
                    [float(r["thermal_peak_any_c"]) for r in group if r["thermal_peak_any_c"] != ""],
                    default="",
                ),
            }
        )
    return sorted(out, key=lambda r: (r["model"], r["prompt"], r["strict_only"], -r["mean_of_run_means_tok_s"]))


def markdown_report(rows: list[dict], naive: list[dict], strict: list[dict], title: str) -> str:
    total = len(rows)
    notes = Counter(r["validity_note"] for r in rows)
    kinds = Counter(r["kind"] for r in rows)
    strict_count = sum(1 for r in rows if r["strict_backend_valid"])
    mismatch = sum(1 for r in rows if r["validity_note"] == "reported_backend_mismatch")
    empty = sum(1 for r in rows if r["validity_note"] in ("empty_or_null_measurement", "partial_or_missing_completion"))
    high_thermal = sum(1 for r in rows if r["validity_note"] == "ok_high_thermal")

    lines = [
        f"# {title}",
        "",
        "## Inventory",
        "",
        f"- Total run directories scanned: {total}",
        f"- Strict-valid runs: {strict_count}",
        f"- Backend-mismatch runs: {mismatch}",
        f"- Empty/partial/null runs: {empty}",
        f"- Strict-valid but high-thermal runs: {high_thermal}",
        "",
        "## Run Families",
        "",
        "| Family | Runs |",
        "|---|---:|",
    ]
    for key, count in sorted(kinds.items()):
        lines.append(f"| {key} | {count} |")
    lines.extend(["", "## Failure Taxonomy", "", "| Validity note | Runs |", "|---|---:|"])
    for key, count in sorted(notes.items()):
        lines.append(f"| {key} | {count} |")
    lines.extend(
        [
            "",
            "## Naive Ranking",
            "",
            "Naive ranking uses every run with throughput, even if requested and reported backends differ.",
            "",
            "| Model | Prompt | Requested backend | Runs | OK rows | Mean tok/s | Max thermal C |",
            "|---|---|---|---:|---:|---:|---:|",
        ]
    )
    for row in naive[:30]:
        lines.append(
            f"| {row['model']} | {row['prompt']} | {row['backend']} | {row['runs']} | {row['ok_rows']} | "
            f"{row['mean_of_run_means_tok_s']} | {row['max_thermal_c']} |"
        )
    lines.extend(
        [
            "",
            "## Validated Ranking",
            "",
            "Validated ranking keeps only runs whose requested backend matches the benchmark-reported backend and that produced measured rows.",
            "",
            "| Model | Prompt | Backend | Runs | OK rows | Mean tok/s | Max thermal C |",
            "|---|---|---|---:|---:|---:|---:|",
        ]
    )
    for row in strict[:30]:
        lines.append(
            f"| {row['model']} | {row['prompt']} | {row['backend']} | {row['runs']} | {row['ok_rows']} | "
            f"{row['mean_of_run_means_tok_s']} | {row['max_thermal_c']} |"
        )
    lines.extend(
        [
            "",
            "## Paper Claim",
            "",
            "The ranking changes after validation. Requested CPU/GPU rows can look competitive in a naive throughput table, "
            "but many report NPU execution in the benchmark CSV. A paper-grade mobile LLM benchmark therefore needs "
            "backend validation, completion validation, null-artifact handling, thermal context, and power-context disclosure.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runs-dir", default="01-sustained-mobile-inference/logs/runs")
    parser.add_argument("--out-dir", default="04-failure-aware-mobile-llm-benchmarking/artifacts")
    args = parser.parse_args()

    runs_dir = Path(args.runs_dir)
    out_dir = Path(args.out_dir)
    run_dirs = sorted([p for p in runs_dir.iterdir() if p.is_dir()])
    rows = [validate_run(p) for p in run_dirs]
    fields = list(rows[0].keys()) if rows else []
    write_csv(out_dir / "mobile-benchmark-inventory.csv", rows, fields)

    taxonomy_rows = [
        {"validity_note": key, "runs": count}
        for key, count in sorted(Counter(r["validity_note"] for r in rows).items())
    ]
    write_csv(out_dir / "failure-taxonomy.csv", taxonomy_rows, ["validity_note", "runs"])

    naive = ranking(rows, strict_only=False)
    strict = ranking(rows, strict_only=True)
    ranking_fields = [
        "model",
        "prompt",
        "backend",
        "strict_only",
        "runs",
        "ok_rows",
        "mean_of_run_means_tok_s",
        "sd_of_run_means_tok_s",
        "max_thermal_c",
    ]
    write_csv(out_dir / "naive-ranking.csv", naive, ranking_fields)
    write_csv(out_dir / "validated-ranking.csv", strict, ranking_fields)
    (out_dir / "mobile-benchmark-validation-report.md").write_text(
        markdown_report(rows, naive, strict, "Mobile Benchmark Validation Report"),
        encoding="utf-8",
    )

    focused = [
        r
        for r in rows
        if r["runtime"] == "litert_lm"
        and "gemma" in str(r["model_name"]).lower()
        and "qnn_litertlm_gemma" in str(r["app_package"]).lower()
        and r["measure_rows"] != 0
    ]
    write_csv(out_dir / "focused-gemma-litertlm-inventory.csv", focused, fields)
    focused_naive = ranking(focused, strict_only=False)
    focused_strict = ranking(focused, strict_only=True)
    write_csv(out_dir / "focused-gemma-litertlm-naive-ranking.csv", focused_naive, ranking_fields)
    write_csv(out_dir / "focused-gemma-litertlm-validated-ranking.csv", focused_strict, ranking_fields)
    (out_dir / "focused-gemma-litertlm-validation-report.md").write_text(
        markdown_report(
            focused,
            focused_naive,
            focused_strict,
            "Focused Gemma LiteRT-LM Benchmark Validation Report",
        ),
        encoding="utf-8",
    )
    print(out_dir / "mobile-benchmark-validation-report.md")
    print(out_dir / "focused-gemma-litertlm-validation-report.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
