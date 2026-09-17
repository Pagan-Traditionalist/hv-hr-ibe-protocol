# Deterministic Protocol Gate — HVHR-IBE-RB-1.2

This document adds a **cross-stage procedural enforcement layer** to the existing stage-gated H-R / H-A / H-V IBE method. It does **not** change the hypotheses, criteria, worldview nodes, record policy, steelman requirements, or comparative IBE rules in `HVHR-IBE-RB-1.1`.

## Purpose

The philosophical protocol answers what the inquiry must do. The Deterministic Protocol Gate answers a different question:

> **Can the run show machine-readable evidence that the required procedure actually occurred under the correct locked inputs?**

Three layers must remain separate:

1. **Substantive inquiry** — Stages 1–7 and their human-readable artifacts.
2. **Neutrality / fairness review** — `NEUTRALITY_GATE.md`, judged by an independent reader.
3. **Procedural verification** — this Deterministic Protocol Gate, implemented in R.

The protocol gate does not decide whether H-R, H-A, or H-V is better supported. It does not decide whether a philosophical claim is true. It checks ordering, provenance, lock continuity, artifact integrity, role separation, required coverage, and gate completion.

## 1.2 constitutional rule

Under `HVHR-IBE-RB-1.2`, Stage 8 is blocked until both conditions are true:

- the live-run Neutrality Gate returns `PASS`; and
- `validation/protocol-gate/protocol_gate.R` returns `PASS` with `stage8_allowed: true`.

A verbal assertion by the Coordinator or any AI that the protocol was followed is not procedural evidence.

## Required run structure

A live run should contain the philosophical artifacts plus a `receipts/` directory:

```text
run/
  ART-01-hypotheses.md
  ART-02-criteria-lock.md
  ART-03-presupposition-tree.md
  ART-04-record-lock.md
  ART-05-dossier.md
  ART-06a-HR-memo.md
  ART-06b-HV-memo.md
  ART-06c-HA-memo.md
  ART-07-audit.md
  NEUTRALITY_GATE.md
  receipts/
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

Paths may differ, but the receipts must point to the actual files relative to the run root.

## Required evidence

### Stages 1–5

Each receipt records at minimum:

- `protocol_version`
- `stage`
- `status`
- `artifact_path`
- `artifact_md5`
- lock timestamp
- locking seat / owner
- `unresolved_fail_items`

The content fingerprint is mandatory. The reference R implementation uses base R `tools::md5sum()` as an integrity fingerprint. It is an integrity check, not a digital signature or adversarial security guarantee.

### Stage 6 — blind triple construction

The Stage-6 receipt additionally records:

- Stage-6 start time;
- the shared official packet fingerprint;
- H-R, H-A, and H-V constructor identities;
- each memo path and fingerprint;
- each memo freeze time;
- a blind-first-pass attestation for each constructor.

The gate verifies that all three builders declare the **same official packet fingerprint**, that their declared roles are distinct, and that all three memos were frozen before the audit began.

The gate cannot prove that a model never saw an unofficial side channel. That remains an attested procedural fact. The system therefore distinguishes **mechanically verified facts** from **declared attestations** instead of pretending they are equivalent.

### Stage 7 — comparative audit

Stage 7 retains the human-readable `ART-07-audit.md` and adds a machine-readable companion, `receipts/stage07-audit-matrix.json`.

The companion must cover:

- both courts: `Court1` and `Court2`;
- all worldview nodes: `B`, `T`, `G`, `C`;
- all locked criteria `C1`–`C8`;
- a legal ordinal label in every required cell;
- all three aggregation lenses per court/node: `Equal`, `C3-heavy`, `C1-heavy`;
- the required honesty tag for each heavy lens.

The R gate checks coverage and legal values. It does **not** decide whether an ordinal label is philosophically justified. Anti-abstention and fairness remain substantive questions for the auditor and Neutrality Gate.

### Neutrality Gate

The completed Neutrality Gate remains a human/AI judgment artifact. Its receipt records:

- independent reader identity;
- completed artifact path and fingerprint;
- overall result;
- unresolved fail count;
- completion time.

The Protocol Gate verifies that this review occurred, was independent as declared, references the correct run, and returned `PASS`. It does not re-perform the neutrality judgment.

## Deterministic failure conditions

The Protocol Gate returns `FAIL` and `stage8_allowed: false` when any required invariant fails, including:

- wrong protocol version;
- missing receipt or artifact;
- artifact fingerprint mismatch after lock;
- Stage 1–5 lock completed after Stage 6 began;
- Stage-6 constructors do not share the same official packet fingerprint;
- missing H-R, H-A, or H-V construction;
- duplicate declared constructor identities;
- missing blind-first-pass attestation;
- Stage 7 begins before all Stage-6 memos are frozen;
- auditor identity equals a constructor identity;
- missing court, node, criterion cell, aggregation lens, or required honesty tag;
- illegal court ordinal label;
- Neutrality Gate incomplete or not `PASS`;
- unresolved procedural fail items greater than zero.

## Execution

From the repository root:

```bash
Rscript validation/protocol-gate/protocol_gate.R /path/to/live-run
```

The gate writes:

```text
/path/to/live-run/protocol_gate_status.json
```

A valid run produces:

```json
{
  "protocol_version": "HVHR-IBE-RB-1.2",
  "result": "PASS",
  "stage8_allowed": true,
  "failures": []
}
```

Any failed invariant produces `FAIL`, `stage8_allowed: false`, a non-zero exit status, and explicit failure messages.

## Version rule

`HVHR-IBE-RB-1.2` is deliberately narrow. It retains the substantive 1.1 method and adds mandatory procedural evidence and deterministic enforcement. Any later change to philosophical content, criteria, worldview nodes, court structure, or audit logic requires a further protocol version bump.
