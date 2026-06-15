#!/usr/bin/env python3
"""Mine logcat files for failure signatures in mobile benchmark runs."""

from __future__ import annotations

import argparse
import csv
import re
from collections import Counter
from pathlib import Path


PATTERNS = {
    "fatal": re.compile(r"\bFATAL\b|Fatal signal", re.I),
    "exception": re.compile(r"\bException\b|Traceback|RuntimeException", re.I),
    "anr_timeout": re.compile(r"\bANR\b|timeout|timed out|not responding", re.I),
    "delegate_backend": re.compile(r"delegate|backend|NPU|GPU|CPU|QNN|LiteRT|TFLite", re.I),
    "memory": re.compile(r"out.?of.?memory|oom|low memory|allocation failed", re.I),
    "thermal": re.compile(r"thermal|throttl|temperature|overheat", re.I),
    "empty_output": re.compile(r"empty|no output|zero rows|null", re.I),
}


def mine_file(path: Path, max_hits_per_kind: int = 5) -> tuple[Counter, dict[str, list[str]]]:
    counts: Counter = Counter()
    examples: dict[str, list[str]] = {k: [] for k in PATTERNS}
    if not path.exists() or path.stat().st_size == 0:
        return counts, examples
    try:
        with path.open("r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                clean = line.strip()
                for kind, pattern in PATTERNS.items():
                    if pattern.search(clean):
                        counts[kind] += 1
                        if len(examples[kind]) < max_hits_per_kind:
                            examples[kind].append(clean[:260])
    except Exception:
        counts["unreadable_logcat"] += 1
    return counts, examples


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", default="04-failure-aware-mobile-llm-benchmarking/artifacts/mobile-benchmark-inventory.csv")
    parser.add_argument("--out-dir", default="04-failure-aware-mobile-llm-benchmarking/artifacts")
    args = parser.parse_args()

    inventory = Path(args.inventory)
    out_dir = Path(args.out_dir)
    rows = []
    with inventory.open("r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))

    out_rows = []
    global_counts: Counter = Counter()
    examples_by_kind: dict[str, list[str]] = {k: [] for k in PATTERNS}

    for row in rows:
        run_dir = Path(row["run_dir"])
        counts, examples = mine_file(run_dir / "logcat.txt")
        global_counts.update(counts)
        for kind, lines in examples.items():
            for line in lines:
                if len(examples_by_kind[kind]) < 12:
                    examples_by_kind[kind].append(f"{row['run_id']}: {line}")
        out = {
            "run_id": row["run_id"],
            "kind": row["kind"],
            "validity_note": row["validity_note"],
            "requested_backend": row["requested_backend"],
            "reported_backends": row["reported_backends"],
            "run_dir": row["run_dir"],
        }
        for kind in PATTERNS:
            out[f"logcat_{kind}_hits"] = counts[kind]
        out_rows.append(out)

    fields = list(out_rows[0].keys()) if out_rows else []
    out_dir.mkdir(parents=True, exist_ok=True)
    with (out_dir / "logcat-failure-signatures.csv").open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(out_rows)

    lines = ["# Logcat Failure Signature Mining", ""]
    lines += ["## Aggregate Hits", "", "| Signature | Hits |", "|---|---:|"]
    for kind, count in sorted(global_counts.items()):
        lines.append(f"| {kind} | {count} |")
    lines += ["", "## Example Lines", ""]
    for kind, examples in examples_by_kind.items():
        if not examples:
            continue
        lines += [f"### {kind}", ""]
        for example in examples:
            safe = example.replace("|", "\\|")
            lines.append(f"- `{safe}`")
        lines.append("")
    (out_dir / "logcat-failure-signatures.md").write_text("\n".join(lines), encoding="utf-8")
    print(out_dir / "logcat-failure-signatures.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
