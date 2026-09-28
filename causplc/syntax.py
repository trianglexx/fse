from __future__ import annotations

from dataclasses import dataclass
import re


@dataclass(frozen=True)
class Assignment:
    target: str
    expression: str
    start: int
    end: int


@dataclass(frozen=True)
class Call:
    name: str
    arguments: str
    start: int
    end: int


@dataclass(frozen=True)
class UnknownStatement:
    text: str
    start: int
    end: int


@dataclass(frozen=True)
class Branch:
    guard: str | None
    guard_start: int | None
    guard_end: int | None
    statements: tuple[Statement, ...]


@dataclass(frozen=True)
class Conditional:
    branches: tuple[Branch, ...]
    start: int
    end: int


Statement = Assignment | Call | UnknownStatement | Conditional


@dataclass(frozen=True)
class Program:
    source: str
    statements: tuple[Statement, ...]
    initial: dict[str, object]
    inputs: tuple[str, ...]
    declared_outputs: frozenset[str] = frozenset()
    sensitive_variables: frozenset[str] = frozenset()


_TOKEN = re.compile(
    r"\s+|\(\*.*?\*\)|//[^\n]*|'(?:''|[^'])*'|\"(?:\"\"|[^\"])*\"|"
    r"[A-Za-z_][A-Za-z_0-9]*|\d+(?:\.\d+)?|:=|<=|>=|<>|\S",
    re.DOTALL,
)
_DECLARATION = re.compile(r"\bVAR(?:_INPUT|_OUTPUT|_IN_OUT|_GLOBAL|_TEMP)?\b.*?\bEND_VAR\b", re.IGNORECASE | re.DOTALL)
_INITIALIZER = re.compile(r"\b([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)(?:\s*:=\s*([^;]+))?\s*;", re.IGNORECASE)
_WRAPPERS = {"PROGRAM", "END_PROGRAM", "FUNCTION_BLOCK", "END_FUNCTION_BLOCK", "FUNCTION", "END_FUNCTION"}


def _tokens(source: str) -> list[tuple[str, int, int]]:
    result = []
    for match in _TOKEN.finditer(source):
        value = match.group()
        if value.isspace() or value.startswith("(*") or value.startswith("//"):
            continue
        result.append((value, match.start(), match.end()))
    return result


def _initial(source: str) -> dict[str, object]:
    values: dict[str, object] = {}
    for block in _DECLARATION.finditer(source):
        for entry in _INITIALIZER.finditer(block.group()):
            name, kind, raw = entry.groups()
            if raw is None:
                if kind.upper() in {"BOOL"}:
                    values[name.upper()] = False
                elif kind.upper() in {"SINT", "INT", "DINT", "LINT", "USINT", "UINT", "UDINT", "ULINT", "BYTE", "WORD", "DWORD", "LWORD", "REAL", "LREAL"}:
                    values[name.upper()] = 0
                continue
            raw = raw.strip()
            if raw.upper() in {"TRUE", "FALSE"}:
                values[name.upper()] = raw.upper() == "TRUE"
            else:
                try:
                    values[name.upper()] = float(raw) if "." in raw else int(raw)
                except ValueError:
                    pass
    return values


class _Parser:
    def __init__(self, source: str):
        self.source = source
        self.tokens = _tokens(source)
        self.index = 0

    def _word(self) -> str:
        return self.tokens[self.index][0].upper() if self.index < len(self.tokens) else ""

    def _take_until(self, terminator: str) -> tuple[str, int, int]:
        start = self.index
        while self.index < len(self.tokens) and self._word() != terminator:
            self.index += 1
        if start == self.index:
            position = self.tokens[start][1] if start < len(self.tokens) else len(self.source)
            return "", position, position
        first = self.tokens[start][1]
        last = self.tokens[self.index - 1][2]
        return self.source[first:last], first, last

    def _plain(self) -> Statement | None:
        text, start, end = self._take_until(";")
        if self._word() == ";":
            end = self.tokens[self.index][2]
            self.index += 1
        stripped = text.strip()
        if not stripped:
            return None
        assignment = re.fullmatch(r"([A-Za-z_]\w*)\s*:=\s*(.+)", stripped, re.DOTALL)
        if assignment:
            return Assignment(assignment.group(1), assignment.group(2).strip(), start, end)
        call = re.fullmatch(r"([A-Za-z_]\w*)\s*\((.*)\)", stripped, re.DOTALL)
        if call:
            return Call(call.group(1), call.group(2), start, end)
        return UnknownStatement(stripped, start, end)

    def _if(self) -> Conditional:
        start = self.tokens[self.index][1]
        branches = []
        while self._word() in {"IF", "ELSIF"}:
            self.index += 1
            guard, first, last = self._take_until("THEN")
            if self._word() == "THEN":
                self.index += 1
            statements = self._body({"ELSIF", "ELSE", "END_IF"})
            branches.append(Branch(guard.strip(), first, last, statements))
        if self._word() == "ELSE":
            self.index += 1
            branches.append(Branch(None, None, None, self._body({"END_IF"})))
        end = self.tokens[self.index][2] if self.index < len(self.tokens) else len(self.source)
        if self._word() == "END_IF":
            self.index += 1
        if self._word() == ";":
            end = self.tokens[self.index][2]
            self.index += 1
        return Conditional(tuple(branches), start, end)

    def _unsupported(self) -> UnknownStatement:
        opener = self._word()
        closer = {"CASE": "END_CASE", "FOR": "END_FOR", "WHILE": "END_WHILE", "REPEAT": "END_REPEAT"}[opener]
        start = self.tokens[self.index][1]
        depth = 0
        while self.index < len(self.tokens):
            word = self._word()
            if word == opener:
                depth += 1
            elif word == closer:
                depth -= 1
                if depth == 0:
                    end = self.tokens[self.index][2]
                    self.index += 1
                    if self._word() == ";":
                        end = self.tokens[self.index][2]
                        self.index += 1
                    return UnknownStatement(self.source[start:end], start, end)
            self.index += 1
        return UnknownStatement(self.source[start:], start, len(self.source))

    def _body(self, stop: set[str]) -> tuple[Statement, ...]:
        statements = []
        while self.index < len(self.tokens) and self._word() not in stop:
            word = self._word()
            if word == "IF":
                statements.append(self._if())
            elif word in {"CASE", "FOR", "WHILE", "REPEAT"}:
                statements.append(self._unsupported())
            elif word in _WRAPPERS:
                self.index += 1
                if word in {"PROGRAM", "FUNCTION_BLOCK", "FUNCTION"} and self.index < len(self.tokens):
                    self.index += 1
            else:
                item = self._plain()
                if item is not None:
                    statements.append(item)
        return tuple(statements)


def parse(source: str) -> Program:
    parser = _Parser(source)
    spans = [(match.start(), match.end()) for match in _DECLARATION.finditer(source)]
    parser.tokens = [token for token in parser.tokens if not any(left <= token[1] < right for left, right in spans)]
    inputs = []
    declared_outputs: set[str] = set()
    sensitive_variables: set[str] = set()
    sensitive_types = {"TON", "TOF", "TP", "CTU", "CTD", "CTUD"}
    section = ""
    for block in re.finditer(r"\bVAR_INPUT\b(.*?)\bEND_VAR\b", source, re.IGNORECASE | re.DOTALL):
        inputs.extend(match.group(1).upper() for match in _INITIALIZER.finditer(block.group(1)))
    for raw_line in source.splitlines():
        line = raw_line.strip()
        marker = re.match(r"\b(VAR(?:_INPUT|_OUTPUT|_IN_OUT|_GLOBAL|_TEMP)?)\b", line, re.IGNORECASE)
        if marker:
            section = marker.group(1).upper()
            continue
        if re.match(r"\bEND_VAR\b", line, re.IGNORECASE):
            section = ""
            continue
        if not section:
            continue
        declaration = re.match(
            r"([A-Za-z_]\w*)\s*(?:AT\s+(%[A-Za-z0-9_.]+)\s*)?:\s*([A-Za-z_]\w*)",
            line,
            re.IGNORECASE,
        )
        if not declaration:
            continue
        name, address, type_name = declaration.groups()
        normalized = name.upper()
        type_upper = type_name.upper()
        if section == "VAR_OUTPUT" or address and address.upper().startswith("%Q"):
            declared_outputs.add(normalized)
            sensitive_variables.add(normalized)
        if type_upper in sensitive_types:
            sensitive_variables.add(normalized)
        if re.search(r"safety|interlock|alarm|warning|fault|emergency|actuator|motor|valve|pump|output", type_upper, re.IGNORECASE):
            sensitive_variables.add(normalized)
    return Program(
        source,
        parser._body(set()),
        _initial(source),
        tuple(dict.fromkeys(inputs)),
        frozenset(declared_outputs),
        frozenset(sensitive_variables),
    )
