from __future__ import annotations

from dataclasses import dataclass

from .discovery import Candidate, discover
from .evidence import Evidence, construct
from .reasoning import Judgment, Model, review
from .syntax import parse


@dataclass(frozen=True)
class CandidateDecision:
    candidate: Candidate
    evidence: Evidence
    judgment: Judgment | None
    malicious: bool


@dataclass(frozen=True)
class Detection:
    label: str
    decisions: tuple[CandidateDecision, ...]


class CausPLC:
    def __init__(self, top_k: int = 3, scan_bound: int = 2, model: Model | None = None):
        if top_k < 1 or scan_bound < 1:
            raise ValueError("top_k and scan_bound must be positive")
        self.top_k = top_k
        self.scan_bound = scan_bound
        self.model = model

    def analyze(self, source: str, initial: dict[str, object] | None = None, inputs: tuple[dict[str, object], ...] = ()) -> Detection:
        program = parse(source)
        decisions = []
        for candidate in discover(program, self.top_k):
            evidence = construct(program, candidate, self.scan_bound, initial, inputs)
            judgment = None
            if evidence.core != 1 and self.model is not None:
                try:
                    judgment = review(program, evidence, self.model)
                except (OSError, ValueError, KeyError, TypeError):
                    judgment = None
            malicious = evidence.core == 1 or judgment is not None and judgment.action == "promote"
            decisions.append(CandidateDecision(candidate, evidence, judgment, malicious))
        return Detection("malicious" if any(item.malicious for item in decisions) else "legitimate", tuple(decisions))
