from __future__ import annotations

from dataclasses import dataclass
import json
from typing import Callable
from urllib.request import Request, urlopen

from .evidence import Evidence
from .execution import UNKNOWN
from .syntax import Program


@dataclass(frozen=True)
class Judgment:
    action: str
    h1_evidence_ids: tuple[str, ...]
    h0_evidence_ids: tuple[str, ...]


def validate(
    raw: object,
    allowed: set[str],
    h1_allowed: set[str] | None = None,
    h0_allowed: set[str] | None = None,
) -> Judgment | None:
    if not isinstance(raw, dict) or raw.get("action") not in {"promote", "reject"}:
        return None
    h1, h0 = raw.get("h1_evidence_ids"), raw.get("h0_evidence_ids")
    if not isinstance(h1, list) or not isinstance(h0, list):
        return None
    if any(not isinstance(value, str) or value not in allowed for value in h1 + h0):
        return None
    if h1_allowed is not None and not set(h1).issubset(h1_allowed):
        return None
    if h0_allowed is not None and not set(h0).issubset(h0_allowed):
        return None
    if raw["action"] == "promote" and not h1:
        return None
    if raw["action"] == "reject" and not h0:
        return None
    return Judgment(raw["action"], tuple(h1), tuple(h0))


def package(program: Program, evidence: Evidence, radius: int = 500) -> dict[str, object]:
    candidate = evidence.candidate
    start = max(0, candidate.trigger_start - radius)
    end = min(len(program.source), candidate.payload_end + radius)
    return {
        "context": program.source[start:end],
        "candidate": {
            "id": candidate.identifier,
            "trigger": candidate.trigger,
            "payload": candidate.payload,
            "sensitive_effect": candidate.effect,
            "discovery": list(candidate.sources),
            "priority": candidate.priority,
        },
        "evidence": evidence.obligations,
        "counterfactual": {name: [None if value is UNKNOWN else value for value in trace.observed()] for name, trace in evidence.traces.items()},
        "reference_ids": sorted(evidence.identifiers()),
    }


class OpenAICompatibleModel:
    def __init__(self, endpoint: str, model: str, api_key: str, timeout: float = 60.0):
        self.endpoint = endpoint
        self.model = model
        self.api_key = api_key
        self.timeout = timeout

    def __call__(self, stage: str, evidence_package: dict[str, object], previous: list[dict[str, object]]) -> object:
        instruction = "Placeholder: return JSON with action, h1_evidence_ids, and h0_evidence_ids."
        request = Request(
            self.endpoint,
            data=json.dumps({
                "model": self.model,
                "temperature": 0,
                "response_format": {"type": "json_object"},
                "messages": [
                    {"role": "system", "content": instruction},
                    {"role": "user", "content": json.dumps({"stage": stage, "package": evidence_package, "previous": previous})},
                ],
            }).encode(),
            headers={"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(request, timeout=self.timeout) as response:
            body = json.load(response)
        return json.loads(body["choices"][0]["message"]["content"])


Model = Callable[[str, dict[str, object], list[dict[str, object]]], object]


def review(program: Program, evidence: Evidence, model: Model) -> Judgment | None:
    content = package(program, evidence)
    allowed = evidence.identifiers()
    values = evidence.obligations
    h1_allowed = {name for name in allowed if values[name] == 1 and name in {"O1", "O2", "O3", "O4", "O6"}}
    h0_allowed = {
        name for name in allowed
        if (name == "O1" and values[name] == 0)
        or (name in {"O2", "O3"} and values[name] == 0)
        or (name == "O5" and values[name] == 1)
    }
    proposer = validate(model("proposer", content, []), allowed, h1_allowed, h0_allowed)
    if proposer is None:
        return None
    history = [{"stage": "proposer", "action": proposer.action, "h1_evidence_ids": proposer.h1_evidence_ids, "h0_evidence_ids": proposer.h0_evidence_ids}]
    critic = validate(model("critic", content, history), allowed, h1_allowed, h0_allowed)
    if critic is None:
        return None
    if critic.action == proposer.action:
        return critic
    history.append({"stage": "critic", "action": critic.action, "h1_evidence_ids": critic.h1_evidence_ids, "h0_evidence_ids": critic.h0_evidence_ids})
    return validate(model("resolver", content, history), allowed, h1_allowed, h0_allowed)
