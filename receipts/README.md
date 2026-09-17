# Machine-readable run receipts

These receipts are **procedural evidence**, not philosophical arguments.

For a live `HVHR-IBE-RB-1.2` run, create a `receipts/` directory inside the run root with these exact live filenames:

```text
stage01.json
stage02.json
stage03.json
stage04.json
stage05.json
stage06.json
stage07.json
stage07-audit-matrix.json
neutrality.json
```

Use the `.example.json` files in this directory as shapes. Do not treat example timestamps, hashes, identities, or results as live evidence.

## Stages 1–5

Copy `stage-lock.example.json` and adjust `stage`, paths, fingerprints, timestamps, and seat identity. The gate accepts `LOCKED`, `FROZEN`, or `PASS` as the stage status, requires `unresolved_fail_items` to be zero, and verifies the referenced artifact fingerprint.

## Stage 6

`stage06.example.json` records the official packet fingerprint and all three blind constructions. All three constructors must declare the same packet fingerprint. Constructor identities must be distinct. Blind-first-pass status is an **attestation**; the gate can verify its presence but cannot independently prove absence of side-channel exposure.

## Stage 7

`stage07.example.json` records the auditor, audit artifact, structured matrix, and timing. The auditor must be distinct from all Stage-6 constructors, and the audit must start only after all three construction memos were frozen.

`stage07-audit-matrix.example.json` is the machine-readable companion to the prose audit. A real run must contain all 64 court/node/criterion cells and all 24 court/node/lens aggregations.

## Neutrality

`neutrality.example.json` records the completed independent Neutrality Gate. The deterministic gate verifies that this review exists and passes; it does not itself judge philosophical fairness.

## Fingerprints

The reference gate uses `tools::md5sum()` so it can run with base R plus `jsonlite`. The MD5 here is a content-integrity fingerprint, not a cryptographic signature or identity proof.
