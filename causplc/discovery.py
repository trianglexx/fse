from __future__ import annotations

from dataclasses import dataclass, replace
import re

from .syntax import Assignment, Call, Conditional, Program, Statement


@dataclass(frozen=True)
class Candidate:
    identifier: str
    trigger: str
    trigger_start: int
    trigger_end: int
    active_when_true: bool
    payload: str
    payload_start: int
    payload_end: int
    effect: str
    category: str
    sources: tuple[str, ...]
    priority: float


_SENSITIVE = {
    "safety": 6.0,
    "interlock": 6.0,
    "alarm": 5.0,
    "emergency": 6.0,
    "stop": 4.0,
    "output": 4.0,
    "actuator": 4.0,
    "motor": 3.0,
    "valve": 3.0,
    "pump": 3.0,
    "state": 3.0,
    "mode": 3.0,
    "timer": 3.0,
    "counter": 3.0,
    "time": 2.0,
    "count": 2.0,
    "q": 2.0,
}


def sensitivity(name: str) -> tuple[str, float] | None:
    words = re.findall(r"[A-Za-z]+|\d+", re.sub(r"([a-z])([A-Z])", r"\1_\2", name).lower())
    scores = [(category, weight) for category, weight in _SENSITIVE.items() if category in words or len(category) > 2 and category in name.lower()]
    return max(scores, key=lambda item: item[1]) if scores else None


def _assignments(statements: tuple[Statement, ...]):
    for statement in statements:
        if isinstance(statement, Assignment):
            yield statement
        elif isinstance(statement, Conditional):
            for branch in statement.branches:
                yield from _assignments(branch.statements)


def _walk(statements: tuple[Statement, ...], guards: tuple[tuple[str, int, int, bool], ...] = ()):
    for statement in statements:
        if isinstance(statement, Conditional):
            previous: list[tuple[str, int, int]] = []
            for branch in statement.branches:
                if branch.guard is None:
                    if previous:
                        expression = " AND ".join(f"NOT ({item[0]})" for item in previous)
                        last = previous[-1]
                        yield from _walk(branch.statements, guards + ((expression, last[1], last[2], False),))
                else:
                    expression = " AND ".join([*(f"NOT ({item[0]})" for item in previous), branch.guard])
                    current = (expression, branch.guard_start or 0, branch.guard_end or 0, True)
                    yield from _walk(branch.statements, guards + (current,))
                    previous.append((branch.guard, branch.guard_start or 0, branch.guard_end or 0))
        else:
            yield statement, guards


def _priority(candidate: Candidate, weight: float) -> float:
    agreement = 2.0 if len(candidate.sources) == 2 else 0.0
    distance = max(0, candidate.payload_start - candidate.trigger_end)
    state = 1.0 if candidate.category in {"state", "mode", "timer", "counter", "time", "count"} else 0.0
    guard = 1.0 if re.search(r"\b(AND|OR|NOT)\b|[<>]=?|\b\d+\b", candidate.trigger, re.IGNORECASE) else 0.0
    return weight + agreement + state + guard + 1.0 / (1.0 + distance / 100.0)


def discover(program: Program, top_k: int = 3) -> tuple[Candidate, ...]:
    assignments = list(_assignments(program.statements))
    uses = {assignment.start: set(re.findall(r"[A-Za-z_]\w*", assignment.expression.upper())) for assignment in assignments}
    declared_sensitive = {name.upper() for name in program.sensitive_variables}

    def sensitive_effect(name: str) -> tuple[str, float] | None:
        result = sensitivity(name)
        if result:
            return result
        normalized = name.upper()
        if normalized in declared_sensitive:
            category = "output" if normalized in program.declared_outputs else "state"
            return category, 4.0
        return None

    dependencies: dict[str, set[str]] = {}
    for assignment in assignments:
        dependencies.setdefault(assignment.target.upper(), set()).update(uses[assignment.start])
    changed = True
    while changed:
        changed = False
        for target, names in tuple(dependencies.items()):
            expanded = set(names)
            for name in names:
                expanded.update(dependencies.get(name, ()))
            if expanded != names:
                dependencies[target] = expanded
                changed = True
    sites = list(_walk(program.statements))
    forward = []
    backward = []
    for statement, guards in sites:
        if not guards or not isinstance(statement, (Assignment, Call)):
            continue
        target = statement.target if isinstance(statement, Assignment) else statement.name
        sensitive = sensitive_effect(target)
        downstream = []
        if isinstance(statement, Assignment):
            downstream = [
                other for other in assignments
                if other.start > statement.start
                and target.upper() in dependencies.get(other.target.upper(), set())
                and sensitive_effect(other.target)
            ]
        for index, (_, guard_start, guard_end, active_when_true) in enumerate(guards):
            guard = " AND ".join(f"({part[0]})" for part in guards[:index + 1])
            if sensitive:
                forward.append((guard, guard_start, guard_end, active_when_true, statement, target, sensitive, "forward"))
            for other in downstream:
                effect = sensitive_effect(other.target)
                if effect:
                    forward.append((guard, guard_start, guard_end, active_when_true, statement, other.target, effect, "forward"))
    for statement, guards in sites:
        if not guards or not isinstance(statement, (Assignment, Call)):
            continue
        target = statement.target if isinstance(statement, Assignment) else statement.name
        sensitive = sensitive_effect(target)
        if sensitive is None:
            continue
        for index, (_, guard_start, guard_end, active_when_true) in enumerate(guards):
            guard = " AND ".join(f"({part[0]})" for part in guards[:index + 1])
            backward.append((guard, guard_start, guard_end, active_when_true, statement, target, sensitive, "backward"))
    merged: dict[tuple[int, int, str], Candidate] = {}
    for guard, guard_start, guard_end, active_when_true, statement, effect, (category, weight), source in forward + backward:
        key = (guard_start, statement.start, effect.upper())
        payload = program.source[statement.start:statement.end].strip()
        candidate = Candidate("", guard, guard_start, guard_end, active_when_true, payload, statement.start, statement.end, effect, category, (source,), 0.0)
        if key in merged:
            sources = tuple(sorted(set(merged[key].sources) | {source}))
            candidate = replace(candidate, sources=sources)
        merged[key] = replace(candidate, priority=_priority(candidate, weight))
    ranked = sorted(merged.values(), key=lambda item: (-item.priority, item.trigger_start, item.payload_start, item.effect))
    return tuple(replace(item, identifier=f"C{index + 1}") for index, item in enumerate(ranked[:top_k]))
