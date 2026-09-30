# Machine-readable run receipts

These receipts are **procedural evidence**, not philosophical arguments.

For a live `HVHR-IBE-RB-1.8` run, create a `receipts/` directory inside the run root with these exact live filenames:

```text
stage01.json
stage02.json
stage03.json
stage04.json
stage04-audit-matrix.json
neutrality.json
```

Use the `.example.json` files in this directory as shapes. Do not treat example timestamps, hashes, identities, or results as live evidence.

## Stages 1–2

Use `stage-lock.example.json` for Stage 1 and `stage02-lock.example.json` for Stage 2; adjust `stage`, paths, fingerprints, timestamps, and seat identity. The gate accepts `LOCKED`, `FROZEN`, or `PASS` as the stage status, requires `unresolved_fail_items` to be zero, and verifies the referenced artifact fingerprint.

## Stage 3

`stage03.example.json` records the official packet fingerprint and both blind constructions. Both constructors must declare the same packet fingerprint. Constructor identities must be distinct. Blind-first-pass status is an **attestation**; the gate can verify its presence but cannot independently prove absence of side-channel exposure.

## Stage 4

`stage04.example.json` records the auditor, audit artifact, structured matrix, and timing. The auditor must be distinct from all Stage-3 constructors, and the audit must start only after both construction memos were frozen.

`stage04-audit-matrix.example.json` is the machine-readable companion to the prose audit. A real run must contain all 32 court/node/criterion cells.

## Neutrality

`neutrality.example.json` records the completed independent Neutrality Gate. The deterministic gate verifies that this review exists and passes; it does not itself judge philosophical fairness.

## Fingerprints

The reference gate uses `tools::md5sum()` so it can run with base R plus `jsonlite`. The MD5 here is a content-integrity fingerprint, not a cryptographic signature or identity proof.


No aggregation rows or weighting-profile tags are required. Record supporting reason IDs, dependence, explained strength, and per-node synthesis in the fingerprinted Stage 4 Markdown artifact; the Neutrality Gate reviews their substance.

## v1.8 consolidated stage receipts

Stage 1 fingerprints `stages/01-frame.md` once and declares `completed_components: ["hypotheses", "criteria", "presuppositions"]`. Stage 2 fingerprints `stages/02-evidence.md` once and declares `completed_components: ["record", "dossier"]`. Each section must pass its component gate before the collective stage lock. The R gate verifies the required component names and full-file integrity; component completion is an attestation, not a machine judgment of philosophical quality.

Stage 1 must lock before Stage 2; both must lock before construction. Live receipts are stage01.json through stage04.json, plus stage04-audit-matrix.json and neutrality.json. Stage 5 is the gated owner judgment. Previous-version receipts are not accepted as v1.8 runs. Earlier schemas remain in Git history.
