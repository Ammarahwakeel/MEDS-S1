# `docs/adr/` — Architecture decision records

## What lives here
One numbered, immutable record per significant decision: the context, the options weighed, the
decision, and the consequences we accepted.

## What does *not* live here
Specifications. An ADR records **why**; `specs/` records **what**. If you find yourself writing
signal names, you want `specs/INTERFACES.md`.

## How to add something
Copy `TEMPLATE.md`, take the next number, open a PR. ADRs are **never edited after acceptance** —
if a decision changes, write a new ADR and mark the old one *Superseded by ADR-NNNN*. The history is
the value: a contributor in 2031 needs to know what was considered and rejected, not just what won.

## Index

| ADR | Decision | Status | Reversibility |
|---|---|---|---|
| [0001](0001-platform-naming.md) | Platform is MEDS-S1; core is S1-Core | Accepted | Very hard |
| [0002](0002-mxif-profile-of-cvxif.md) | MXIF-1.0 is a documented profile of CV-X-IF | Accepted | Very hard |
| [0003](0003-two-phase-completion.md) | Two-phase MXIF completion (`x_norollback`) | Accepted | Very hard |
| [0004](0004-256-bit-backbone.md) | 256-bit AXI4 memory backbone | Accepted | Hard |
| [0005](0005-sram-wrapper-mandate.md) | All memory behind `meds_s1_sram` | Accepted | Medium |

The full 24-row decision log lives in [`ADDENDUM.md`](../../ADDENDUM.md) Part E. Rows rated
*Very hard* to reverse get an ADR here; the rest are recorded in the log alone.

## Catalogue projects that land here
architects (T3 tier only)
