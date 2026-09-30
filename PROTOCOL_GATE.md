# Deterministic Protocol Gate — HVHR-IBE-RB-1.6

This document adds a **cross-stage procedural enforcement layer** to the existing stage-gated H-R / H-V IBE method. It does **not** change the hypotheses, criteria, worldview nodes, record policy, steelman requirements, or comparative IBE rules in `HVHR-IBE-RB-1.6`.

## Purpose

The philosophical protocol answers what the inquiry must do. The Deterministic Protocol Gate answers a different question:

> **Can the run show machine-readable evidence that the required procedure actually occurred under the correct locked inputs?**

Three layers must remain separate:

1. **Substantive inquiry** — Stages 1–4 and their human-readable artifacts.
2. **Neutrality / fairness review** — `NEUTRALITY_GATE.md`, judged by an independent reader.
3. **Procedural verification** — this Deterministic Protocol Gate, implemented in R.

The protocol gate does not decide whether H-R or H-V is better supported. It does not decide whether a philosophical claim is true. It checks ordering, provenance, lock continuity, artifact integrity, role separation, required coverage, and gate completion.

## 1.6 constitutional rule

Under `HVHR-IBE-RB-1.6`, Stage 5 is blocked until both conditions are true:

- the live-run Neutrality Gate returns `PASS`; and
- `validation/protocol-gate/protocol_gate.R` returns `PASS` with `stage5_allowed: true`.

A verbal assertion by the Coordinator or any AI that the protocol was followed is not procedural evidence.

## Required run structure

A live run should contain the philosophical artifacts plus a `receipts/` directory:

```text
run/
  stages/01-frame.md
  stages/02-evidence.md
  stages/03-construct/HR.md
  stages/03-construct/HV.md
  stages/04-compare.md
  NEUTRALITY_GATE.md
  receipts/
    stage01.json
    stage02.json
    stage03.json
    stage04.json
    stage04-audit-matrix.json
    neutrality.json
```

Paths may differ, but the receipts must point to the actual files relative to the run root.

## Required evidence

### Stages 1–2

Each receipt records at minimum:

- `protocol_version`
- `stage`
- `status`
- `artifact_path` and `artifact_md5`: the consolidated stage file and its fingerprint
- `completed_components`: ordered names of all approved sections
- lock timestamp
- locking seat / owner
- `unresolved_fail_items`

The content fingerprint is mandatory. The reference R implementation uses base R `tools::md5sum()` as an integrity fingerprint. It is an integrity check, not a digital signature or adversarial security guarantee.

### Stage 3 — blind dual construction

The Stage-3 receipt additionally records:

- Stage-3 start time;
- the shared official packet fingerprint;
- H-R and H-V constructor identities;
- each memo path and fingerprint;
- each memo freeze time;
- a blind-first-pass attestation for each constructor.

The gate verifies that both builders declare the **same official packet fingerprint**, that their declared roles are distinct, and that both memos were frozen before the audit began.

The gate cannot prove that a model never saw an unofficial side channel. That remains an attested procedural fact. The system therefore distinguishes **mechanically verified facts** from **declared attestations** instead of pretending they are equivalent.

### Stage 4 — comparative audit

Stage 4 retains the human-readable `stages/04-compare.md` and adds a machine-readable companion, `receipts/stage04-audit-matrix.json`.

The companion must cover:

- the sole comparison: `court: "HR-HV"`;
- all worldview nodes: `B`, `T`, `G`, `C`;
- all locked criteria `C1`–`C8`;
- a legal ordinal label in every required cell;
- all three aggregation lenses per node: `Equal`, `C3-heavy`, `C1-heavy`;
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

The Protocol Gate returns `FAIL` and `stage5_allowed: false` when any required invariant fails, including:

- wrong protocol version;
- missing receipt or artifact;
- artifact fingerprint mismatch after lock;
- Stages 1–2 lock completed after Stage 3 began;
- Stage-3 constructors do not share the same official packet fingerprint;
- missing H-R or H-V construction;
- duplicate declared constructor identities;
- missing blind-first-pass attestation;
- Stage 4 begins before all Stage-3 memos are frozen;
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
  "protocol_version": "HVHR-IBE-RB-1.6",
  "result": "PASS",
  "stage5_allowed": true,
  "failures": []
}
```

Any failed invariant produces `FAIL`, `stage5_allowed: false`, a non-zero exit status, and explicit failure messages.

## Version rule

`HVHR-IBE-RB-1.6` uses two constructors and one H-R vs H-V comparison under the five stages while retaining the existing substantive rules and deterministic enforcement. Any later change to philosophical content, criteria, worldview nodes, court structure, or audit logic requires a further protocol version bump.


## v1.6 consolidated stage receipts

Stage 1 fingerprints `stages/01-frame.md` once and declares `completed_components: ["hypotheses", "criteria", "presuppositions"]`. Stage 2 fingerprints `stages/02-evidence.md` once and declares `completed_components: ["record", "dossier"]`. Each section must pass its component gate before the collective stage lock. The R gate verifies the required component names and full-file integrity; component completion is an attestation, not a machine judgment of philosophical quality.

Stage 1 must lock before Stage 2; both must lock before construction. Live receipts are stage01.json through stage04.json, plus stage04-audit-matrix.json and neutrality.json. Stage 5 is the gated owner judgment. Previous-version receipts are not accepted as v1.6 runs. Earlier schemas remain in Git history.
