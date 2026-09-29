# HVHR-IBE-RB-1.3

Supersedes `HVHR-IBE-RB-1.2` for new runs. Authorized by Owner on 2026-09-29 (America/Chicago).

## Scope

Reorganize eight stages into five without changing the existing hypothesis atomics, abductive criteria, or substantive comparison rules.

| Previous stage(s) | Current stage | Stable artifact IDs |
|---|---|---|
| 1 Hypothesis Formulation; 2 Abductive Criteria Lock; 3 Presupposition Lock | 1 Frame | ART-01, ART-02, ART-03 |
| 4 Record Lock; 5 Shared Dossier | 2 Establish the evidence | ART-04, ART-05 |
| 6 Triple Construction | 3 Construct explanations | ART-06a/b/c |
| 7 Comparative Audit | 4 Compare and challenge | ART-07 |
| 8 Interpretation | 5 Judge | ART-08 |

## Preserved

- Exact H-R, H-A, and H-V hypothesis atomics in ART-01.
- Both pairwise courts and their ordinal labels.
- All C1–C8 definitions, default weights, Equal/C3-heavy/C1-heavy lenses, and honesty tags.
- B/T/G/C nodes, evidence tiers and sensitivity slices, blind construction, role separation, anti-abstention, and justified underdetermination.
- Mandatory component gates, artifact fingerprints, receipts, independent Neutrality Gate, and deterministic Protocol Gate.

## Receipt migration

Stage 1 now records three ordered component artifacts (hypotheses, criteria, presuppositions). Stage 2 records two (record, dossier). Construction receipts move to stage03.json; audit receipts and matrix move to stage04.json and stage04-audit-matrix.json. Stage 5 requires `result: PASS` and `stage5_allowed: true`.

ART filenames stay stable. Existing runs remain pinned to their original version; do not relabel old receipts as v1.3 evidence. A new run must satisfy the new receipt schema.

## Controlling documents

The updated runbook, PROTOCOL_GATE.md, and locked live artifacts govern the reissued master prompt. ART-01 contains the authoritative existing hypothesis identities; ART-02 contains the authoritative existing criteria. Earlier working paraphrases do not replace these pack baselines.

No mid-run method or receipt-schema edits without a further version bump and reissued launcher.
