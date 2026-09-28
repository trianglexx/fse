# PLC logic bomb dataset

This folder contains 214 paired Structured Text samples (428 program files).
Files with the same name in `original/` and `logic_bomb/` form one pair.
`original/` is the pre-injection source (`clean_code`); it is not a verified benign label.
`logic_bomb/` is the injected source (`vul_code`).
`manifest.csv` lists each pair and its source provenance.
The dataset contains 51 deterministic records and 163 assisted records.
