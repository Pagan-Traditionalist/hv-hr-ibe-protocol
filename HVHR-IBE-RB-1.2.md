# HVHR-IBE-RB-1.2

`HVHR-IBE-RB-1.2` supersedes `HVHR-IBE-RB-1.1` for new runs.

## Scope of 1.2

Version 1.2 **does not change the substantive philosophical method** frozen in 1.1. The following remain unchanged unless separately version-bumped later:

- H-R / H-A / H-V hypothesis identities;
- the two pairwise courts;
- C1–C8 abductive criteria;
- B / T / G / C worldview nodes;
- record tiers and sensitivity slices;
- blind triple construction;
- Stage-7 comparative IBE and anti-abstention;
- Equal / C3-heavy / C1-heavy aggregation lenses;
- Neutrality Gate substantive/fairness standards.

Version 1.2 adds a **deterministic procedural enforcement layer**:

1. mandatory machine-readable stage receipts;
2. mandatory artifact integrity fingerprints;
3. mandatory Stage-7 structured audit companion;
4. machine checks for ordering, version continuity, role separation, required coverage, and unresolved failures;
5. Stage 8 blocked unless both the Neutrality Gate and Deterministic Protocol Gate pass.

## Controlling documents

For `HVHR-IBE-RB-1.2`, the method constitution is:

1. `hv-hr-stage-gated-protocol.md` — substantive 1.1 runbook;
2. `PROTOCOL_GATE.md` — 1.2 procedural enforcement addendum;
3. locked live-run stage artifacts — source of truth for the particular run;
4. `hv-hr-master-prompt.md` — thin stage router only.

If the launcher conflicts with the substantive runbook, procedural addendum, or locked live artifacts, the **runbook + procedural addendum + locked artifacts win**.

## Freeze rule

No mid-run change to the method constitution, receipt schema, or gate invariants. A substantive or procedural rule change requires a version bump and a re-issued Master Prompt.

## Stage-8 rule

Stage 8 may begin only when:

- the live-run `NEUTRALITY_GATE.md` is complete and `PASS`;
- `protocol_gate_status.json` reports `result: PASS`;
- `protocol_gate_status.json` reports `stage8_allowed: true`.

Coordinator assertions do not override gate failure.
