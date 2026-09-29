# Five-stage abductive inquiry

**Version:** `HVHR-IBE-RB-1.4` — H-R / H-A / H-V, two pairwise courts. This repository contains the method and templates, not a resurrection verdict.

## Start here

Use the [Master Prompt](hv-hr-master-prompt.md) with the [runbook](hv-hr-stage-gated-protocol.md). The working files follow the five stages:

| Stage | Working file | What it contains |
|---|---|---|
| **1. Frame** | [01-frame.md](stages/01-frame.md) | Your existing hypotheses, C1–C8 abductive criteria, and worldview assumptions |
| **2. Establish the evidence** | [02-evidence.md](stages/02-evidence.md) | Record lock, shared dossier, and supporting ledgers |
| **3. Construct explanations** | [03-construct/](stages/03-construct/) | Separate [H-R](stages/03-construct/HR.md), [H-A](stages/03-construct/HA.md), and [H-V](stages/03-construct/HV.md) memos |
| **4. Compare and challenge** | [04-compare.md](stages/04-compare.md) | Both pairwise comparisons, locked criteria, and sensitivity tests |
| **5. Judge** | [05-judge.md](stages/05-judge.md) | Owner judgment and keep/cut after both gates pass |

Stage 3 needs three files because builders must not see each other's drafts. Give each builder the same frozen Frame/Evidence packet plus only its own construction template. Do not send the full working construction folder to a builder.

The H-R, H-A, and H-V atomics and all C1–C8 definitions, weights, ordinal rules, and aggregation lenses are preserved. Frame still requires separate approvals for hypotheses, criteria, and presuppositions; Evidence still requires record and dossier approval.

## Required support

- [Neutrality Gate](NEUTRALITY_GATE.md): independent substantive/fairness review after Stage 4.
- [Protocol Gate](PROTOCOL_GATE.md): receipt rules and deterministic checks; Stage 5 requires PASS.
- [Receipt examples](receipts/README.md): machine-readable evidence for each completed stage and the independent review.
- [R validator and tests](validation/protocol-gate/README.md): executable procedure checks, run automatically by GitHub Actions.

The runbook, procedural gate, and locked live-run artifacts govern the launcher. Stage 5 requires `result: PASS` and `stage5_allowed: true`.

## Version continuity

Version 1.4 consolidates the working files to match the five-stage method. Superseded ART files, version-marker files, and merge notes have been removed from the current tree; earlier versions remain in Git history. Start new runs with v1.4. Do not relabel old receipts as new evidence.
