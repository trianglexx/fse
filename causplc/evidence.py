from __future__ import annotations

from dataclasses import dataclass
import re

from .discovery import Candidate, sensitivity
from .execution import UNKNOWN, Trace, contrast, scan, witness
from .syntax import Program


Tri = int | None


def conjunction(*values: Tri) -> Tri:
    if 0 in values:
        return 0
    if None in values:
        return None
    return 1


@dataclass(frozen=True)
class Evidence:
    candidate: Candidate
    obligations: dict[str, Tri]
    core: Tri
    witness: dict[str, object] | None
    traces: dict[str, Trace]

    def identifiers(self) -> set[str]:
        return {name for name, value in self.obligations.items() if value is not None}


def _benign(program: Program, candidate: Candidate) -> Tri:
    start = max(0, candidate.trigger_start - 250)
    end = min(len(program.source), candidate.payload_end + 250)
    window = program.source[start:end]
    if re.search(r"\b(reset|startup|start_up|shutdown|fault|recovery|manual|safe_stop|emergency_stop|complete|timeout)\b", window, re.IGNORECASE):
        return 1
    return None


def _persistence(trigger_on: Trace, trigger_off: Trace) -> Tri:
    on, off = trigger_on.observed(), trigger_off.observed()
    if len(on) < 2:
        return None
    if any(value is UNKNOWN for value in on + off):
        return None
    for index in range(len(on) - 1):
        if on[index] != off[index] and on[index] == on[index + 1] and on[index + 1] != off[index + 1]:
            return 1
    return 0


def construct(program: Program, candidate: Candidate, cycles: int = 2, initial: dict[str, object] | None = None, inputs: tuple[dict[str, object], ...] = ()) -> Evidence:
    seed = dict(program.initial)
    if initial:
        seed.update({key.upper(): value for key, value in initial.items()})
    assigned = {match.group(1).upper() for match in re.finditer(r"\b([A-Za-z_]\w*)\s*:=", program.source)}
    external = set(program.inputs) | {name.upper() for name in re.findall(r"[A-Za-z_]\w*", candidate.trigger) if name.upper() not in assigned and name.upper() not in {"AND", "OR", "NOT", "TRUE", "FALSE"}}
    found, impossible = witness(candidate.trigger, seed, external)
    state = found if found is not None else seed
    guard_span = (candidate.trigger_start, candidate.trigger_end)
    baseline = scan(program, state, candidate.effect, guard_span, candidate.active_when_true, candidate.payload_start, "baseline", cycles, inputs)
    traces = {
        variant: scan(program, state, candidate.effect, guard_span, candidate.active_when_true, candidate.payload_start, variant, cycles, inputs)
        for variant in ("trigger_on", "trigger_off", "payload_mask")
    }
    trigger_contrast = contrast(traces["trigger_on"], traces["trigger_off"]) if traces["trigger_on"].guard_values and traces["trigger_off"].guard_values else None
    payload_contrast = contrast(traces["trigger_on"], traces["payload_mask"]) if candidate.active_when_true in traces["payload_mask"].guard_values else None
    obligations = {
        "O1": 1 if candidate.active_when_true in baseline.guard_values else 0 if found is None and impossible else None,
        "O2": trigger_contrast,
        "O3": payload_contrast,
        "O4": 1 if sensitivity(candidate.effect) or candidate.effect.upper() in program.sensitive_variables else 0,
        "O5": _benign(program, candidate),
        "O6": _persistence(traces["trigger_on"], traces["trigger_off"]),
    }
    return Evidence(candidate, obligations, conjunction(*(obligations[f"O{index}"] for index in range(1, 5))), found, traces)
