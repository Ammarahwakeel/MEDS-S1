# ADR-0003 — Two-phase MXIF completion

## Context

ADR-0002 puts MXIF offload at the retire pointer. Taken alone that is fatal to the whole point of a
decoupled coprocessor: a vector instruction running 300 cycles would sit at the head of the
completion buffer for 300 cycles, nothing younger could retire, the 8-entry buffer would fill, and
the pipeline would stall. The core would be decoupled in name only.

## Options considered

### A. Retire on completion
Correct, and eliminates decoupling. Rejected.

### B. Retire on accept, report faults late
Breaks precise exceptions — younger instructions have already retired when the fault arrives.

### C. Separate "cannot fault" from "has finished"
Two events, only the first gating retire.

## Decision

Option C. `specs/INTERFACES.md` §1.4a, R1.9–R1.11:

- **`x_norollback`** — the coprocessor has completed every check that could raise an exception
  (address generation, PMA/PMP, alignment, register-group legality). After asserting it, it **shall
  not** report a fault for that id.
- **`x_result_valid`** — the instruction has finished and, if applicable, produces a scalar result.

An offloaded instruction retires when `x_norollback` has arrived **and**, if `x_issue_writeback` was
asserted, `x_result_valid` has too.

## Consequences

**Good:** a `vle32.v` retires two cycles after its address range clears the checks and keeps
fetching for another dozen — the scalar pipeline runs unrelated work throughout. Only instructions
writing a scalar register (`vsetvli`, `vmv.x.s`) stall, which is exactly the set MEDS-V's book
already identifies.

**Bad:** a retired-but-executing instruction is architecturally invisible, so there is nothing to
trap to if it faults afterwards.

**We accept:** R1.9 becomes a hard obligation on every coprocessor — **eager fault checking**. For a
vector load that means computing and checking the whole `vl`-derived byte range *before* issuing any
memory request. MEDS-V's VLSU must do that anyway (its book warns against fetching VLEN/8 bytes when
`vl` is smaller, precisely because it could fault on an access the program never made), so this
formalises an obligation the design already has.

**Also:** a trap handler that switches context must wait for `x_idle` before saving coprocessor
state. Phase-5 concern, recorded here because it is a consequence of this decision.

## Revisit when

Never for v1. This is what makes decoupling and in-order retire coexist.
