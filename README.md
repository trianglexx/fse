# CausPLC

This project contains the CausPLC Python package and a collection of PLC Structured Text (ST) programs.

## Project structure

```text
causplc_public_stage/
├── README.md                Project overview
├── pyproject.toml           Package configuration and CLI entry point
├── causplc/                 Python implementation
│   ├── __init__.py          Package initialization
│   ├── __main__.py          Entry point for python -m causplc
│   ├── cli.py               Command-line arguments and JSON output
│   ├── syntax.py            ST parsing
│   ├── discovery.py         Candidate trigger and effect discovery
│   ├── execution.py         Expression evaluation and execution traces
│   ├── evidence.py          Candidate evidence construction
│   ├── reasoning.py         Evidence packaging and optional model review
│   └── pipeline.py          Analysis pipeline and result aggregation
└── dataset/                 ST program samples
    ├── README.md            Dataset directory overview
    ├── manifest.csv         Sample pairing manifest
    ├── original/            214 original programs
    └── logic_bomb/          214 corresponding logic bomb programs
```

Files with the same `.st` filename in `dataset/original/` and `dataset/logic_bomb/` form a pair. The command-line entry point is defined in `pyproject.toml`. You can also run the package with `python -m causplc`.
