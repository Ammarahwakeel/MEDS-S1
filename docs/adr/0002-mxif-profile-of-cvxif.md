# ADR-0002 — MXIF-1.0 is a documented profile of CV-X-IF

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-03 |
| **Deciders** | Umer Shahid, MEDS-V owner |
| **Reversibility** | Very hard |

## Context

The platform needs a tightly-coupled coprocessor interface. The obvious move is to adopt OpenHW's
CV-X-IF wholesale.

But MEDS-V has already published one — book Ch 8.4, headed *"write it down, review it, freeze it,
version it"* — and it is **not** CV-X-IF. It has no commit/kill channel, and it uses an independent
wide memory port instead of CV-X-IF's memory channels.

That gap is not cosmetic. The platform's frontend uses static BTFN prediction, so instructions in ID
are speculative. Offloading from ID with no kill channel means a branch mispredict can leave an
already-accepted vector store in flight — silent data corruption, visible only under branch-heavy
vector code, which is exactly what strip-mine loops are.

## Options considered

### A. Full CV-X-IF; MEDS-V gets a shim
Standards-aligned, but the shim must buffer issued instructions until commit — real logic, and it
re-litigates a contract MEDS-V's book calls frozen.

### B. MEDS-V's interface becomes the MEDS standard
Cheapest today. Abandons interoperability with every OpenHW core and coprocessor and undercuts the
standards-first identity the lab is building.

### C. A documented *profile* of CV-X-IF
Keeps CV-X-IF signal names and semantics, defines a subset, and adds clearly-marked MEDS extensions.

## Decision

Option C — **MXIF-1.0**, specified normatively in `specs/INTERFACES.md` §1. Three profile decisions:

1. **Non-speculative issue (R1.1).** The core asserts `x_issue_valid` only at the retire pointer, so
   the instruction is architecturally certain. `x_commit_kill` is therefore always 0.
2. **The commit channel exists in RTL from day one (R1.3)**, doing nothing. Adding wires later is a
   rewrite; making a wire do something later is an afternoon.
3. **`x_idle` and `x_issue_pc` are marked as MEDS extensions**, not passed off as standard.

## Consequences

**Good:** MEDS-V is legal as designed; a conforming CV-X-IF coprocessor works unmodified on a
MXIF-1.0 core; the upgrade path to speculative issue is a version bump, not a redesign.
**Bad:** compatibility is one-way — a MXIF-1.0 coprocessor is not necessarily a valid CV-X-IF
coprocessor for a speculative core.
**We accept:** ~2 cycles of extra offload latency. Noise for MEDS-V, measurable for single-cycle
custom ops.

## Revisit when

A measurement shows offload latency dominates a real workload. Then MXIF-1.1 relaxes R1.1 and
requires coprocessors to buffer.
