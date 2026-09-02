# `meds_s1_lite_regif`

| | |
|---|---|
| **Status** | SKELETON — ports frozen, the implementation is T-05 work |
| **Owner** | _(shared — both students, at G1)_ |
| **Backup** | _(each other)_ |
| **Project** | T-05, consumed by M-01 · M-02 · M-03 · R-07 |
| **Spec** | INTERFACES.md §3 (I4), SPEC §24, ADR-0005 |
| **Source** | `rtl/peripherals/meds_s1_lite_regif.sv` |
| **Testbench** | `verif/unit/tb_meds_s1_lite_regif.sv` — **you write this** |

> **This page is the specification you are implementing.** Unlike the CLINT and PLIC pages, the
> contract here is not yours to decide — four other projects will code against it, so it is written
> out in full below. Read it before you touch the RTL. What is missing is only the
> _Behaviour_, _Verification status_ and _Known limitations_ sections, which you fill in from what
> you actually built.

## Purpose

The AXI4-Lite slave handshake, written once. Every peripheral on the MEDS-S1 peripheral subtree
instantiates this and then implements only a register file — a combinational read decode and a
strobed write decode. Nobody in this repository writes AXI4-Lite handshaking twice.

It also absorbs the one consequence of a 64-bit peripheral bus (ADR-0005): a 32-bit peripheral sets
`REG_DW = 32`, never sees the upper half of the bus, and is byte-for-byte what it would have been on
a 32-bit bus. CLINT sets `REG_DW = 64` because `mtime` and `mtimecmp` must move in one access.

This is the most reused module in T-05. Build it first.

## Interface contract

### Bus side — I4, frozen

| Signal | Dir | Width | Meaning | Contract |
|---|---|---|---|---|
| `clk_i` | in | 1 | clock | single domain |
| `rst_ni` | in | 1 | reset | async assert, sync de-assert |
| `lite_req_i` | in | `lite_req_t` | master-driven channels | `valid` stable with payload until `ready` |
| `lite_rsp_o` | out | `lite_rsp_t` | slave-driven channels | no `ready` depends on its own `valid`; no `valid` depends on a `ready` (R-C10) |

`AW` and `W` must be accepted **independently and in either order**. A slave that requires `AW`
first deadlocks against a master that presents `W` first, which AXI4-Lite permits.

### Register-file side — what a peripheral implements

| Signal | Dir | Width | Meaning | Contract |
|---|---|---|---|---|
| `addr_o` | out | `ADDR_W` | **byte** offset in the window, aligned down to `REG_DW/8` | a peripheral decodes it against the literal offsets in its register-map table |
| `we_o` | out | 1 | write strobe | one cycle; never high with `re_o` |
| `re_o` | out | 1 | read strobe | one cycle; only needed for read-side-effect registers |
| `wdata_o` | out | `REG_DW` | write data, already shifted out of its bus lane | |
| `wstrb_o` | out | `REG_DW/8` | byte enables | a peripheral must honour these |
| `rdata_i` | in | `REG_DW` | read data | **combinational**, valid in the same cycle as `re_o` |
| `err_i` | in | 1 | "nothing is mapped at `addr_o`" | combinational from `addr_o`; becomes `SLVERR` |

**Backpressure:** responses are held until accepted, with the payload stable.
**Reset state:** all `valid` low, all `ready` low, no register access issued.
**Latency:** _(G1: state it once you have built it — and state the throughput, because a peripheral
author needs to know whether back-to-back accesses cost one cycle or three.)_

## Parameters

| Parameter | Default | Legal range | Effect |
|---|---|---|---|
| `ADDR_W` | 16 | 3 … `LITE_AW` | window size in address bits; 64 KiB → 16, 4 MiB → 22. Comes from the region's `size` in `configs/*.yaml` |
| `REG_DW` | 32 | 32 or 64 | register-file width. Must be `LITE_DW` or `LITE_DW/2`; fail at elaboration otherwise |

## Exceptions and errors

| Condition | Response |
|---|---|
| `err_i` asserted for the decoded offset | `SLVERR` |
| Write strobes span both 32-bit lanes when `REG_DW = 32` | `SLVERR`, and **no** register is written |
| Anything else | `OKAY` |

## Behaviour

_(G1.)_ Describe the channel capture, the read/write arbitration and why it cannot starve either
side, and how the byte lane is selected. A state diagram only if it earns its place.

## Verification status

_(G1.)_

| Layer | Status | Where |
|---|---|---|
| Lint | clean (skeleton) | `make lint` |
| Unit test | — | `verif/unit/tb_meds_s1_lite_regif.sv` |
| Mutation | — | run it at the G1 review; see the testbench header |

## Known limitations

_(G1. One is already known and is here as the example of what this section is for:)_

- **An 8-byte read of a 32-bit register file cannot be rejected.** AXI4-Lite carries no size on the
  read channel, so the adapter can only return the register in its own lane and zero in the other.
  Only the PMA `widths` list forbids the access (INTERFACES.md rule P3), and that check lives in the
  LSU. Writes *are* caught, because the strobes reveal the width.

## Open questions

_(G1.)_
