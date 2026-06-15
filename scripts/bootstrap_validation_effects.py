#!/usr/bin/env python3
"""Bootstrap analyses for the failure-aware mobile benchmark paper."""

from __future__ import annotations

import argparse
import csv
import json
import random
from collections import Counter
from pathlib import Path
from statistics import mean


def read_csv(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def fnum(value):
    if value in ("", None):
        return None
    try:
        return float(value)
    except Exception:
        return None


def quantile(values: list[float], q: float) -> float:
    if not values:
        return float("nan")
    vals = sorted(values)
    idx = min(len(vals) - 1, max(0, int(round(q * (len(vals) - 1)))))
    return vals[idx]


def ci(values: list[float]) -> dict:
    return {
        "mean": round(mean(values), 6),
        "ci95_low": round(quantile(values, 0.025), 6),
        "ci95_high": round(quantile(values, 0.975), 6),
    }


def bootstrap_share(rows: list[dict], predicate, n_boot: int, rng: random.Random) -> dict:
    if not rows:
        return {"mean": "", "ci95_low": "", "ci95_high": ""}
    vals = []
    for _ in range(n_boot):
        sample = [rows[rng.randrange(len(rows))] for _ in range(len(rows))]
        vals.append(sum(1 for r in sample if predicate(r)) / len(sample))
    return ci(vals)


def bootstrap_mean(rows: list[dict], value_fn, n_boot: int, rng: random.Random) -> dict:
    vals0 = [value_fn(r) for r in rows]
    vals0 = [v for v in vals0 if v is not None]
    if not vals0:
        return {"mean": "", "ci95_low": "", "ci95_high": ""}
    vals = []
    for _ in range(n_boot):
        sample = [vals0[rng.randrange(len(vals0))] for _ in range(len(vals0))]
        vals.append(mean(sample))
    return ci(vals)


def write_csv(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = list(rows[0].keys()) if rows else []
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", default="04-failure-aware-mobile-llm-benchmarking/artifacts/mobile-benchmark-inventory.csv")
    parser.add_argument("--focused", default="04-failure-aware-mobile-llm-benchmarking/artifacts/focused-gemma-litertlm-inventory.csv")
    parser.add_argument("--strict", default="04-failure-aware-mobile-llm-benchmarking/artifacts/strict-backend-evidence/strict-backend-runs.csv")
    parser.add_argument("--out-dir", default="04-failure-aware-mobile-llm-benchmarking/artifacts/bootstrap-validation")
    parser.add_argument("--boot", type=int, default=5000)
    parser.add_argument("--seed", type=int, default=20260611)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    inventory = read_csv(Path(args.inventory))
    focused = read_csv(Path(args.focused))
    strict = read_csv(Path(args.strict))
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    metrics = []
    metric_specs = [
        ("global_backend_mismatch_share", inventory, lambda r: r.get("validity_note") == "reported_backend_mismatch"),
        ("global_partial_or_missing_share", inventory, lambda r: r.get("validity_note") == "partial_or_missing_completion"),
        ("global_all_measurements_failed_share", inventory, lambda r: r.get("validity_note") == "all_measurements_failed"),
        ("focused_backend_mismatch_share", focused, lambda r: r.get("validity_note") == "reported_backend_mismatch"),
        ("focused_high_thermal_ge100_share", focused, lambda r: (fnum(r.get("thermal_peak_any_c")) or -1) >= 100),
        ("focused_usb_powered_share", focused, lambda r: r.get("validity_note") == "ok_usb_powered"),
    ]
    for name, rows, pred in metric_specs:
        result = bootstrap_share(rows, pred, args.boot, rng)
        metrics.append({"metric": name, "n": len(rows), **result})

    strict_cpu = [r for r in strict if r.get("requested_backend") == "CPU" and int(r.get("ok_measure_rows") or 0) > 0]
    strict_gpu = [r for r in strict if r.get("requested_backend") == "GPU"]
    for prompt in sorted({r.get("prompt") for r in strict_cpu if r.get("prompt")}):
        rows = [r for r in strict_cpu if r.get("prompt") == prompt]
        result = bootstrap_mean(rows, lambda r: fnum(r.get("mean_tok_s")), args.boot, rng)
        metrics.append({"metric": f"strict_cpu_{prompt}_mean_tok_s", "n": len(rows), **result})

    metrics.append(
        {
            "metric": "strict_gpu_success_share",
            "n": len(strict_gpu),
            **bootstrap_share(strict_gpu, lambda r: int(r.get("ok_measure_rows") or 0) > 0, args.boot, rng),
        }
    )

    mismatch_counter = Counter(
        (r.get("requested_backend", ""), r.get("reported_backends", ""))
        for r in focused
        if r.get("validity_note") == "reported_backend_mismatch"
    )
    mismatch_rows = [
        {"requested_backend": k[0], "reported_backends": k[1], "runs": v}
        for k, v in sorted(mismatch_counter.items())
    ]

    write_csv(out_dir / "bootstrap-metrics.csv", metrics)
    write_csv(out_dir / "focused-mismatch-breakdown.csv", mismatch_rows)
    (out_dir / "bootstrap-summary.json").write_text(
        json.dumps({"boot": args.boot, "seed": args.seed, "metrics": metrics, "focused_mismatch_breakdown": mismatch_rows}, indent=2),
        encoding="utf-8",
    )

    lines = [
        "# Bootstrap Validation Effects",
        "",
        f"- Bootstrap samples: {args.boot}",
        f"- Global runs: {len(inventory)}",
        f"- Focused Gemma LiteRT-LM runs: {len(focused)}",
        f"- Strict backend runs: {len(strict)}",
        "",
        "## Bootstrap metrics",
        "",
        "| Metric | N | Mean | CI95 low | CI95 high |",
        "|---|---:|---:|---:|---:|",
    ]
    for row in metrics:
        lines.append(f"| {row['metric']} | {row['n']} | {row['mean']} | {row['ci95_low']} | {row['ci95_high']} |")
    lines += ["", "## Focused mismatch breakdown", "", "| Requested | Reported | Runs |", "|---|---|---:|"]
    for row in mismatch_rows:
        lines.append(f"| {row['requested_backend']} | {row['reported_backends']} | {row['runs']} |")
    lines += [
        "",
        "Interpretation: these intervals quantify the robustness of the paper's main validation claims. "
        "They should be used as support for methodology claims, not as population estimates over all mobile devices.",
        "",
    ]
    (out_dir / "bootstrap-validation-effects.md").write_text("\n".join(lines), encoding="utf-8")
    print(out_dir / "bootstrap-validation-effects.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
