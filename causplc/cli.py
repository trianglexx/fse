from __future__ import annotations

import argparse
from dataclasses import asdict
import json
import os
from pathlib import Path

from .pipeline import CausPLC
from .execution import UNKNOWN
from .reasoning import OpenAICompatibleModel


def main() -> None:
    parser = argparse.ArgumentParser(prog="causplc")
    parser.add_argument("source", type=Path)
    parser.add_argument("--top-k", type=int, default=3)
    parser.add_argument("--scan-bound", type=int, default=2)
    parser.add_argument("--initial", default="{}")
    parser.add_argument("--inputs", default="[]")
    parser.add_argument("--endpoint")
    parser.add_argument("--model")
    arguments = parser.parse_args()
    initial = json.loads(arguments.initial)
    inputs = json.loads(arguments.inputs)
    if not isinstance(initial, dict) or not isinstance(inputs, list) or any(not isinstance(item, dict) for item in inputs):
        parser.error("initial must be an object and inputs must be an array of objects")
    provider = None
    if arguments.endpoint or arguments.model:
        key = os.environ.get("CAUSPLC_API_KEY")
        if not arguments.endpoint or not arguments.model or not key:
            parser.error("endpoint, model, and CAUSPLC_API_KEY are required together")
        provider = OpenAICompatibleModel(arguments.endpoint, arguments.model, key)
    source = arguments.source.read_text(encoding="utf-8")
    result = CausPLC(arguments.top_k, arguments.scan_bound, provider).analyze(source, initial, tuple(inputs))
    output = {
        "label": result.label,
        "candidates": [
            {
                "candidate": asdict(item.candidate),
                "evidence": item.evidence.obligations,
                "core": item.evidence.core,
                "witness": item.evidence.witness,
                "counterfactual": {name: [None if value is UNKNOWN else value for value in trace.observed()] for name, trace in item.evidence.traces.items()},
                "judgment": asdict(item.judgment) if item.judgment else None,
                "malicious": item.malicious,
            }
            for item in result.decisions
        ],
    }
    print(json.dumps(output, ensure_ascii=False, default=str))
