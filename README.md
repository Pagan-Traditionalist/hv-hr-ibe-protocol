# HVHR-IBE-RB-1.2

Stage-gated protocol for comparing **H-R**, **H-A**, and **H-V** in **two pairwise courts** (not a three-way blended winner). Method pack — procedure, not a verdict. Ships pack-baseline ART-01/ART-02 plus empty stage shells for ART-03…ART-08, the Neutrality Gate, and a deterministic cross-stage Protocol Gate.

Account: **Nyklot**.

## Version

`HVHR-IBE-RB-1.2` supersedes 1.1 for new runs.

**1.2 is deliberately narrow:** the substantive philosophical method remains the 1.1 method. Version 1.2 adds mandatory machine-readable receipts, artifact integrity fingerprints, a structured Stage-7 audit companion, deterministic procedural checks, and a Stage-8 block unless both the Neutrality Gate and Protocol Gate pass.

For 1.2, the controlling order is:

1. `hv-hr-stage-gated-protocol.md` — substantive runbook;
2. `PROTOCOL_GATE.md` — 1.2 procedural enforcement addendum;
3. locked live-run stage artifacts;
4. `hv-hr-master-prompt.md` — thin launcher only.

If the launcher conflicts with the runbook, procedural addendum, or locked stage artifacts, **runbook + procedural addendum + locked artifacts win**.

## Architecture

```text
Runbook + locked stage rules
          ↓
Stages 1–7 substantive inquiry
          ↓
Neutrality Gate
(substantive/fairness judgment)
          ↓
Deterministic Protocol Gate
(procedure/provenance/integrity)
          ↓ PASS
Stage 8 owner interpretation / keep-cut
```

The deterministic gate does **not** do philosophy. It verifies that the required procedure actually left the required evidence.

## Hypotheses (ART-01)

| ID | Name | Role |
|----|------|------|
| **H-R** | Transformed-bodily resurrection | God raised Jesus into transformed bodily life; risen Jesus caused encounters |
| **H-A** | Appearance class | No raised body; encounters via pre-registered appearance-type pathways; subpath switches cost C4/C6/C7 |
| **H-V** | Veridical extra-mental apparition | Restricted veridical subpath of H-A — harder anti-H-R rival when extra-mental veridical appearance is granted |

**Two courts:** (1) **H-R vs H-A** — need bodily resurrection at all? (2) **H-R vs H-V** — even granting veridical appearance, is raised body better?

Mode ≠ source retained. No named metaphysics in H-A / H-V identities.

## 1.1 substantive repairs retained in 1.2

- Anti-abstention / comparative IBE for Stage 7 — **Neutrality ≠ abstention**; unpaid bridges ≠ auto-`insuf`; abstention = protocol Fail
- Neutrality = fair criteria + fair data, not withholding labels
- Research / effort split: thin **B**/**G**; concentrate on **T** and **C**
- Slim tree **B / T / G / C** with MF shared on every node
- Stage-7 aggregation lenses over the same C1–C8 cells per court: **Equal** (primary), **C3-heavy**, **C1-heavy**
- Honesty tags **ARGUED+LOCKED/SMUGGLED** and **EVIDENCE-BRIDGE/SLOGAN-FIT**
- Three locked identities + two pairwise courts

| Node | Layer (+ shared MF) |
|------|---------------------|
| **B** | Metaphysical agnosticism + MF |
| **T** | OpenTI + MF |
| **G** | God + MF |
| **C** | God + MF + Christian worldview presuppositions |

## 1.2 procedural additions

- Mandatory stage receipts for Stages 1–7 plus the Neutrality Gate
- Mandatory content fingerprints for locked artifacts
- Shared official Stage-6 packet manifest and packet fingerprint
- Machine-readable Stage-7 audit matrix covering both courts, B/T/G/C, C1–C8, and all three aggregation lenses
- Deterministic checks for stage order, artifact continuity, constructor/auditor separation, required coverage, and unresolved Fail items
- GitHub Actions tests with deliberate failure cases
- Stage 8 blocked unless `protocol_gate_status.json` says `PASS` and `stage8_allowed: true`

## Files

| File | Role |
|------|------|
| [hv-hr-stage-gated-protocol.md](hv-hr-stage-gated-protocol.md) | Substantive runbook retained from 1.1 |
| [PROTOCOL_GATE.md](PROTOCOL_GATE.md) | 1.2 deterministic procedural-enforcement addendum |
| [hv-hr-master-prompt.md](hv-hr-master-prompt.md) | Stage-routed Master Prompt |
| [ART-01-hypotheses.md](ART-01-hypotheses.md) | Pack baseline — locked H-R / H-A / H-V + two courts |
| [ART-02-criteria.md](ART-02-criteria.md) | Pack baseline C1–C8 + court ordinals + Stage-7 lenses |
| [ART-03-presupposition-tree.md](ART-03-presupposition-tree.md) | Empty shell — slim tree B/T/G/C |
| [ART-04-record-lock.md](ART-04-record-lock.md) | Empty shell — tiers + slices A/B/C |
| [ART-05-dossier.md](ART-05-dossier.md) | Empty shell — shared dossier |
| [ART-05-thin-ledgers.md](ART-05-thin-ledgers.md) | Empty shell — thin ledgers stub |
| [ART-06a-HR-memo.md](ART-06a-HR-memo.md) | Empty shell — blind H-R memo |
| [ART-06b-HV-memo.md](ART-06b-HV-memo.md) | Empty shell — blind H-V memo |
| [ART-06c-HA-memo.md](ART-06c-HA-memo.md) | Empty shell — blind H-A construction |
| [ART-07-audit.md](ART-07-audit.md) | Empty shell — Stage 7 both courts |
| [ART-08-interpretation.md](ART-08-interpretation.md) | Empty shell — owner keep/cut |
| [NEUTRALITY_GATE.md](NEUTRALITY_GATE.md) | Substantive/fairness hostile-reader gate |
| [receipts/README.md](receipts/README.md) | Machine-readable receipt shapes and instructions |
| [validation/protocol-gate/README.md](validation/protocol-gate/README.md) | R gate execution and limits |
| [validation/protocol-gate/protocol_gate.R](validation/protocol-gate/protocol_gate.R) | Deterministic procedural referee |
| [HVHR-IBE-RB-1.2.md](HVHR-IBE-RB-1.2.md) | 1.2 freeze marker |
| [HVHR-IBE-RB-1.1.md](HVHR-IBE-RB-1.1.md) | Historical 1.1 freeze marker |

## Compact rule

> **The runbook defines the inquiry; the stage artifacts preserve the reasoning; the Neutrality Gate judges fairness; the deterministic Protocol Gate verifies procedural compliance; the Owner retains final philosophical judgment.**
