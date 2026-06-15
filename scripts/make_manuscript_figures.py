#!/usr/bin/env python3
"""Generate manuscript figures from the validation artifact tables."""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path

import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"
OUT = ROOT / "paper-springer" / "figures"


def labelize(value: str) -> str:
    return value.replace("_", " ").replace("ok", "OK").title().replace("Usb", "USB")


def save(fig: plt.Figure, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(OUT / name, bbox_inches="tight")
    plt.close(fig)


def global_taxonomy() -> None:
    rows = list(csv.DictReader((ARTIFACTS / "failure-taxonomy.csv").open(encoding="utf-8-sig")))
    rows = sorted(rows, key=lambda r: int(r["runs"]))
    labels = [labelize(r["validity_note"]) for r in rows]
    values = [int(r["runs"]) for r in rows]

    fig, ax = plt.subplots(figsize=(6.6, 2.6))
    bars = ax.barh(labels, values, color="#4C78A8")
    ax.set_xlabel("Runs")
    ax.set_title("Global validation taxonomy (316 run directories)")
    ax.bar_label(bars, padding=3, fontsize=8)
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "fig-global-taxonomy.pdf")


def backend_confusion() -> None:
    rows = list(csv.DictReader((ARTIFACTS / "focused-gemma-backend-confusion.csv").open(encoding="utf-8-sig")))
    labels = [f"{r['requested_backend']} -> {r['reported_backends']}" for r in rows]
    values = [int(r["runs"]) for r in rows]
    colors = ["#E45756" if not label.startswith("NPU") else "#54A24B" for label in labels]

    fig, ax = plt.subplots(figsize=(5.4, 2.2))
    bars = ax.bar(labels, values, color=colors)
    ax.set_ylabel("Runs")
    ax.set_title("Requested backend versus reported backend")
    ax.bar_label(bars, padding=3, fontsize=8)
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "fig-backend-confusion.pdf")


def thermal_sensitivity() -> None:
    rows = list(csv.DictReader((ARTIFACTS / "sensitivity" / "thermal-threshold-sensitivity.csv").open(encoding="utf-8-sig")))
    rows = [r for r in rows if int(float(r["thermal_threshold_c"])) in {80, 90, 100, 105}]
    x = [int(float(r["thermal_threshold_c"])) for r in rows]
    total = [int(r["runs_at_or_above_threshold"]) for r in rows]
    strict = [int(r["strict_valid_at_or_above"]) for r in rows]
    mismatch = [int(r["backend_mismatch_at_or_above"]) for r in rows]

    fig, ax = plt.subplots(figsize=(5.6, 2.3))
    ax.plot(x, total, marker="o", linewidth=2.0, label="All focused")
    ax.plot(x, strict, marker="o", linewidth=2.0, label="Strict-valid")
    ax.plot(x, mismatch, marker="o", linewidth=2.0, label="Mismatch")
    ax.set_xlabel("Thermal threshold (C)")
    ax.set_ylabel("Runs at or above threshold")
    ax.set_title("Thermal-threshold sensitivity")
    ax.legend(frameon=False, fontsize=8)
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "fig-thermal-sensitivity.pdf")


def run_family_decomposition() -> None:
    rows = list(csv.DictReader((ARTIFACTS / "focused-gemma-litertlm-inventory.csv").open(encoding="utf-8-sig")))
    family_labels = {
        "backend_replication": "Backend repetition",
        "endurance": "Extended backend checks",
        "other": "Sustained NPU extension",
        "overnight_chunked": "Long-duration NPU",
        "prompt_matrix": "Prompt-backend matrix",
        "prompt_replication": "Prompt repetition",
        "prompt_resume": "Repeated prompt-backend trials",
        "repair": "Follow-up NPU",
        "smoke": "Initial backend checks",
    }
    counts: dict[str, Counter[str]] = defaultdict(Counter)
    for row in rows:
        family = family_labels.get(row["kind"], row["kind"].replace("_", " ").title())
        note = row["validity_note"]
        if note == "reported_backend_mismatch":
            group = "Mismatch"
        elif note == "ok_high_thermal":
            group = "High thermal"
        elif note == "ok_usb_powered":
            group = "USB powered"
        elif note == "ok":
            group = "Plain OK"
        else:
            group = "Other"
        counts[family][group] += 1

    families = sorted(counts, key=lambda f: sum(counts[f].values()))
    groups = ["Mismatch", "High thermal", "USB powered", "Plain OK", "Other"]
    colors = {
        "Mismatch": "#E45756",
        "High thermal": "#F58518",
        "USB powered": "#4C78A8",
        "Plain OK": "#54A24B",
        "Other": "#B279A2",
    }

    fig, ax = plt.subplots(figsize=(7.0, 2.8))
    left = [0] * len(families)
    for group in groups:
        values = [counts[f][group] for f in families]
        ax.barh(families, values, left=left, color=colors[group], label=group)
        left = [l + v for l, v in zip(left, values)]
    ax.set_xlabel("Runs")
    ax.set_title("Focused subset by run family and validity label")
    ax.legend(frameon=False, fontsize=8, ncol=3, loc="lower right")
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "fig-family-decomposition.pdf")


def prompt_validity() -> None:
    rows = list(csv.DictReader((ARTIFACTS / "focused-gemma-litertlm-inventory.csv").open(encoding="utf-8-sig")))
    counts: dict[str, Counter[str]] = defaultdict(Counter)
    max_temp: dict[str, float] = defaultdict(float)
    for row in rows:
        prompt = (row["prompt"] or "unknown").title()
        if row["strict_backend_valid"] == "True":
            counts[prompt]["Strict"] += 1
        elif row["validity_note"] == "reported_backend_mismatch":
            counts[prompt]["Mismatch"] += 1
        else:
            counts[prompt]["Other"] += 1
        try:
            max_temp[prompt] = max(max_temp[prompt], float(row["thermal_peak_any_c"] or 0))
        except ValueError:
            pass

    prompts = ["Short", "Medium", "Long", "Unknown"]
    groups = ["Strict", "Mismatch", "Other"]
    colors = {"Strict": "#54A24B", "Mismatch": "#E45756", "Other": "#B279A2"}

    fig, ax = plt.subplots(figsize=(5.6, 2.3))
    bottom = [0] * len(prompts)
    for group in groups:
        values = [counts[p][group] for p in prompts]
        ax.bar(prompts, values, bottom=bottom, color=colors[group], label=group)
        bottom = [b + v for b, v in zip(bottom, values)]
    ax.set_ylabel("Runs")
    ax.set_title("Prompt-level validity summary")
    ax.legend(frameon=False, fontsize=8, ncol=3)
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "fig-prompt-validity.pdf")


def validity_throughput() -> None:
    rows = list(csv.DictReader((ARTIFACTS / "focused-gemma-litertlm-inventory.csv").open(encoding="utf-8-sig")))
    values: dict[str, list[float]] = defaultdict(list)
    for row in rows:
        note = row["validity_note"]
        if note not in {"ok", "ok_usb_powered", "ok_high_thermal", "reported_backend_mismatch"}:
            continue
        try:
            tok_s = float(row["mean_tok_s"])
        except ValueError:
            continue
        label = {
            "ok": "OK",
            "ok_usb_powered": "OK, USB powered",
            "ok_high_thermal": "OK, high thermal",
            "reported_backend_mismatch": "Backend mismatch",
        }[note]
        values[label].append(tok_s)

    labels = ["OK", "OK, USB powered", "OK, high thermal", "Backend mismatch"]
    means = [sum(values[l]) / len(values[l]) for l in labels]
    sds = []
    for label, mean in zip(labels, means):
        xs = values[label]
        sds.append((sum((x - mean) ** 2 for x in xs) / max(len(xs) - 1, 1)) ** 0.5)

    fig, ax = plt.subplots(figsize=(5.8, 2.3))
    bars = ax.bar(range(len(labels)), means, yerr=sds, capsize=3, color=["#54A24B", "#4C78A8", "#F58518", "#E45756"])
    ax.set_xticks(range(len(labels)), labels, rotation=18, ha="right")
    ax.set_ylabel("Mean tokens/s")
    ax.set_title("Throughput by validity label")
    ax.bar_label(bars, labels=[f"{m:.1f}" for m in means], padding=3, fontsize=8)
    ax.spines[["top", "right"]].set_visible(False)
    save(fig, "fig-validity-throughput.pdf")


def main() -> None:
    plt.rcParams.update({
        "font.size": 9,
        "axes.titlesize": 10,
        "axes.labelsize": 9,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    })
    global_taxonomy()
    backend_confusion()
    thermal_sensitivity()
    run_family_decomposition()
    prompt_validity()
    validity_throughput()


if __name__ == "__main__":
    main()
