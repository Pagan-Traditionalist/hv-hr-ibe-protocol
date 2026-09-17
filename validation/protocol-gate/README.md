# R Deterministic Protocol Gate

This directory implements the **procedural** gate defined by `PROTOCOL_GATE.md`.

It is intentionally narrower than the philosophical protocol:

- it does not score H-R, H-A, or H-V;
- it does not decide whether a criterion application is philosophically warranted;
- it does not re-run the Neutrality Gate;
- it does verify that the required receipts, artifacts, locks, roles, ordering, fingerprints, and Stage-7 coverage are present and internally consistent.

## Dependency

The gate uses base R plus `jsonlite`.

```r
install.packages("jsonlite")
```

## Run

```bash
Rscript validation/protocol-gate/protocol_gate.R /path/to/live-run
```

The live-run root must contain `receipts/stage01.json` through `stage07.json`, `receipts/stage07-audit-matrix.json`, and `receipts/neutrality.json`, with paths inside those receipts pointing to the actual run artifacts.

The gate writes `protocol_gate_status.json` into the live-run root.

A failed invariant returns a non-zero process exit code and blocks Stage 8.

## What is mechanically verified

The gate checks, among other things:

- exact protocol version (`HVHR-IBE-RB-1.2`);
- artifact existence and MD5 integrity fingerprints;
- Stage 1–5 lock ordering before Stage 6;
- identical declared official packet fingerprint across all Stage-6 constructors;
- three distinct constructors for H-R, H-A, and H-V;
- blind-first-pass attestations are present;
- all construction memos freeze before Stage 7 begins;
- Stage-7 auditor is not a constructor;
- all 64 required court/node/criterion cells are present with legal labels;
- all 24 required court/node/lens aggregations are present;
- required C3-heavy and C1-heavy honesty tags are present;
- Neutrality Gate receipt is `PASS` and independent as declared;
- unresolved fail counts are zero.

## What is not mechanically proved

The program cannot prove that an AI never saw an unofficial side channel, that a steelman is genuinely the strongest possible steelman, or that an ordinal judgment is philosophically correct. Those remain substantive / attested questions governed by the runbook and Neutrality Gate.

## Tests

```bash
Rscript validation/protocol-gate/tests/test_protocol_gate.R
```

The test suite constructs a valid synthetic run and deliberate failures for artifact tampering, auditor/constructor role collision, and incomplete Stage-7 coverage.
