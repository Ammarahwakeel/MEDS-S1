# ADR-0005 — All memory goes through `meds_s1_sram`

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-08-03 |
| **Deciders** | Umer Shahid, tech lead |
| **Reversibility** | Medium — mechanical but touches every array |

## Context

Arrays get inferred by accident. A register file written as `logic [63:0] regs [32]` synthesises to
LUT RAM on FPGA and to nothing sensible on ASIC. By the time anyone wants a tape-out there are
thirty such arrays scattered across the design, each with its own latency assumption.

Read latency is the second half of the problem: a design where some memories answer combinationally
and some after a cycle is where timing closure and verification both go to die.

## Decision

Every array in MEDS-S1 — register file, cache tags, cache data, TLB, VRF, any FIFO deeper than 32
entries — is instantiated through `rtl/common/meds_s1_sram.sv`. No exceptions.

**Read latency is one cycle, registered output, everywhere.**

`IMPL` selects the backing store: behavioural (simulation), FPGA BRAM, ASIC macro. Read-during-write
returns old data, stated explicitly rather than left to the technology.

Enforced by `scripts/check_structure.py` rule S7, which flags any packed-array declaration outside
the wrapper.

## Consequences

**Good:** an ASIC port becomes a matter of writing one `IMPL` variant; every consumer already
assumes one-cycle latency, so nothing has to be re-timed.
**Bad:** consumers that would benefit from combinational read (a small bypass FIFO, say) pay a cycle
or have to justify an exemption.
**We accept:** slightly more verbose RTL at every array, in exchange for the tape-out option staying
open at near-zero cost today.

## Revisit when

A profiled critical path is genuinely blocked by the registered output. Even then the fix is a
documented second wrapper variant, not ad-hoc inference.
