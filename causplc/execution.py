from __future__ import annotations

import ast
from dataclasses import dataclass
from itertools import product
import re

from .syntax import Assignment, Call, Conditional, Program, Statement, UnknownStatement


class _Unknown:
    pass


UNKNOWN = _Unknown()


def _python_expression(expression: str) -> str:
    expression = re.sub(r"\bTRUE\b", "True", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bFALSE\b", "False", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bAND\b", "and", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bOR\b", "or", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bNOT\b", "not", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bXOR\b", "^", expression, flags=re.IGNORECASE)
    expression = re.sub(r"\bMOD\b", "%", expression, flags=re.IGNORECASE)
    expression = expression.replace("<>", "!=")
    expression = re.sub(r"(?<![:<>=!])=(?!=)", "==", expression)
    return expression


def _value(node: ast.AST, state: dict[str, object]) -> object:
    if isinstance(node, ast.Constant) and type(node.value) in {int, float, bool, str}:
        return node.value
    if isinstance(node, ast.Name):
        return state.get(node.id.upper(), UNKNOWN)
    if isinstance(node, ast.Attribute):
        parts = []
        current: ast.AST = node
        while isinstance(current, ast.Attribute):
            parts.append(current.attr)
            current = current.value
        if isinstance(current, ast.Name):
            parts.append(current.id)
            return state.get(".".join(reversed(parts)).upper(), UNKNOWN)
        return UNKNOWN
    if isinstance(node, ast.UnaryOp):
        value = _value(node.operand, state)
        if value is UNKNOWN:
            return UNKNOWN
        if isinstance(node.op, ast.Not):
            return not bool(value)
        if isinstance(node.op, ast.USub) and type(value) in {int, float}:
            return -value
        return UNKNOWN
    if isinstance(node, ast.BoolOp):
        values = [_value(part, state) for part in node.values]
        if isinstance(node.op, ast.And):
            return False if False in values else UNKNOWN if UNKNOWN in values else all(bool(value) for value in values)
        if isinstance(node.op, ast.Or):
            return True if True in values else UNKNOWN if UNKNOWN in values else any(bool(value) for value in values)
    if isinstance(node, ast.BinOp):
        left, right = _value(node.left, state), _value(node.right, state)
        if left is UNKNOWN or right is UNKNOWN:
            return UNKNOWN
        try:
            if isinstance(node.op, ast.Add):
                return left + right
            if isinstance(node.op, ast.Sub):
                return left - right
            if isinstance(node.op, ast.Mult):
                return left * right
            if isinstance(node.op, ast.Div):
                return left / right
            if isinstance(node.op, ast.Mod):
                return left % right
            if isinstance(node.op, ast.BitXor):
                return bool(left) ^ bool(right) if type(left) is bool and type(right) is bool else left ^ right
            if isinstance(node.op, ast.Pow):
                return left ** right
        except (TypeError, ValueError, ZeroDivisionError):
            return UNKNOWN
    if isinstance(node, ast.Compare):
        left = _value(node.left, state)
        for operator, comparator in zip(node.ops, node.comparators):
            right = _value(comparator, state)
            if left is UNKNOWN or right is UNKNOWN:
                return UNKNOWN
            try:
                result = (
                    left == right if isinstance(operator, ast.Eq) else
                    left != right if isinstance(operator, ast.NotEq) else
                    left < right if isinstance(operator, ast.Lt) else
                    left <= right if isinstance(operator, ast.LtE) else
                    left > right if isinstance(operator, ast.Gt) else
                    left >= right if isinstance(operator, ast.GtE) else UNKNOWN
                )
            except TypeError:
                return UNKNOWN
            if result is UNKNOWN or not result:
                return result
            left = right
        return True
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
        name = node.func.id.upper()
        arguments = [_value(argument, state) for argument in node.args]
        if any(value is UNKNOWN for value in arguments):
            return UNKNOWN
        try:
            if name == "ABS" and len(arguments) == 1:
                return abs(arguments[0])
            if name == "MIN" and arguments:
                return min(arguments)
            if name == "MAX" and arguments:
                return max(arguments)
            if name == "SEL" and len(arguments) == 3:
                return arguments[2] if bool(arguments[0]) else arguments[1]
            if name == "LIMIT" and len(arguments) == 3:
                return min(max(arguments[1], arguments[0]), arguments[2])
            if name in {"BOOL", "INT", "DINT", "SINT", "UINT", "UDINT", "REAL", "LREAL"} and len(arguments) == 1:
                return bool(arguments[0]) if name == "BOOL" else int(arguments[0]) if name in {"INT", "DINT", "SINT", "UINT", "UDINT"} else float(arguments[0])
        except (TypeError, ValueError, OverflowError):
            return UNKNOWN
        return UNKNOWN
    return UNKNOWN


def evaluate(expression: str, state: dict[str, object]) -> object:
    try:
        return _value(ast.parse(_python_expression(expression), mode="eval").body, state)
    except (SyntaxError, ValueError, TypeError):
        return UNKNOWN


def witness(guard: str, initial: dict[str, object], searchable: set[str] | None = None, limit: int = 4096) -> tuple[dict[str, object] | None, bool]:
    if guard.strip().upper() == "FALSE":
        return None, True
    try:
        tree = ast.parse(_python_expression(guard), mode="eval")
    except SyntaxError:
        return None, False
    names = sorted({node.id.upper() for node in ast.walk(tree) if isinstance(node, ast.Name)})
    values: dict[str, list[object]] = {}
    for name in names:
        base = [initial[name]] if name in initial else []
        values[name] = list(dict.fromkeys(base + [False, True, 0, 1])) if searchable is None or name in searchable else base
        if not values[name]:
            return None, False
    for node in ast.walk(tree):
        if isinstance(node, ast.Compare) and isinstance(node.left, ast.Name):
            name = node.left.id.upper()
            if searchable is not None and name not in searchable:
                continue
            for comparison in node.comparators:
                if isinstance(comparison, ast.Constant) and type(comparison.value) in {int, float}:
                    value = comparison.value
                    values[name] = list(dict.fromkeys(values[name] + [value - 1, value, value + 1]))
    size = 1
    for choices in values.values():
        size *= len(choices)
    if size > limit:
        return None, False
    for combination in product(*(values[name] for name in names)):
        state = dict(initial)
        state.update(dict(zip(names, combination)))
        if evaluate(guard, state) is True:
            return state, True
    return None, False


@dataclass(frozen=True)
class Trace:
    states: tuple[dict[str, object], ...]
    effect: str
    guard_values: tuple[object, ...]

    def observed(self) -> tuple[object, ...]:
        return tuple(state.get(self.effect.upper(), UNKNOWN) for state in self.states[1:])


def _execute(statements: tuple[Statement, ...], state: dict[str, object], guard_span: tuple[int, int], active_when_true: bool, payload_start: int, variant: str, guard_values: list[object]) -> None:
    for statement in statements:
        if isinstance(statement, Assignment):
            if variant == "payload_mask" and statement.start == payload_start:
                continue
            state[statement.target.upper()] = evaluate(statement.expression, state)
        elif isinstance(statement, Call):
            state[statement.name.upper()] = UNKNOWN
        elif isinstance(statement, Conditional):
            selected = False
            unresolved = False
            for branch in statement.branches:
                if unresolved:
                    for nested in _targets(branch.statements):
                        state[nested.upper()] = UNKNOWN
                    continue
                if branch.guard is None:
                    if not selected:
                        _execute(branch.statements, state, guard_span, active_when_true, payload_start, variant, guard_values)
                    continue
                if (branch.guard_start, branch.guard_end) == guard_span and variant in {"trigger_on", "trigger_off"}:
                    condition = (variant == "trigger_on") == active_when_true
                else:
                    condition = evaluate(branch.guard, state)
                if (branch.guard_start, branch.guard_end) == guard_span:
                    guard_values.append(condition)
                if condition is UNKNOWN:
                    unresolved = True
                    for nested in _targets(branch.statements):
                        state[nested.upper()] = UNKNOWN
                elif condition and not selected:
                    _execute(branch.statements, state, guard_span, active_when_true, payload_start, variant, guard_values)
                    selected = True
                    break
        elif isinstance(statement, UnknownStatement):
            for match in re.finditer(r"\b([A-Za-z_]\w*)\s*:=", statement.text):
                state[match.group(1).upper()] = UNKNOWN


def _targets(statements: tuple[Statement, ...]):
    for statement in statements:
        if isinstance(statement, Assignment):
            yield statement.target
        elif isinstance(statement, Call):
            yield statement.name
        elif isinstance(statement, Conditional):
            for branch in statement.branches:
                yield from _targets(branch.statements)


def scan(program: Program, initial: dict[str, object], effect: str, guard_span: tuple[int, int], active_when_true: bool, payload_start: int, variant: str, cycles: int, inputs: tuple[dict[str, object], ...] = ()) -> Trace:
    state = dict(program.initial)
    state.update({key.upper(): value for key, value in initial.items()})
    states = [dict(state)]
    guard_values: list[object] = []
    for index in range(cycles):
        if inputs:
            state.update({key.upper(): value for key, value in inputs[min(index, len(inputs) - 1)].items()})
        _execute(program.statements, state, guard_span, active_when_true, payload_start, variant, guard_values)
        states.append(dict(state))
    return Trace(tuple(states), effect, tuple(guard_values))


def contrast(first: Trace, second: Trace) -> int | None:
    left, right = first.observed(), second.observed()
    if any(value is UNKNOWN for value in left + right):
        return None
    return int(left != right)
