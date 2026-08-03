# MEDS-S1

**An open RISC-V SoC platform for accelerator research**
Maktab-e-Digital Systems (MEDS), UET Lahore · Apache-2.0

> **Status: pre-RTL.** This repository currently holds the design documentation set. Nothing here is
> frozen until the Phase-0 design review. RTL begins in Phase 0 week 6.

---

## What this is

MEDS-S1 is a RISC-V system-on-chip platform whose purpose is **to be attached to**. The scalar core
is deliberately conventional; the value is in the frozen attachment interfaces, the SoC generator,
the verification harness, the BSP, and the measurement infrastructure that makes every attached
accelerator's performance claim comparable to every other one's.

It exists to support MS and PhD work in **Edge AI** and **healthcare electronics** — so that a
thesis student's contribution is the accelerator and the measurement, not the plumbing.

| Component | What it is |
|---|---|
| **MEDS-S1** | the platform: SoC, generator, BSP, CI, board ports |
| **S1-Core** | the scalar RV64IMAC CPU inside it |
| **MEDS-V** | the RVV vector coprocessor ([separate repo](../RVV)), attached over MXIF |
| **MXIF** | the tightly-coupled extension interface; a profile of OpenHW CV-X-IF |
| **MEDS-X-\<name\>** | any accelerator built for MEDS-S1 |

---

## The document set

Read in this order.

| # | Document | What it answers | Audience |
|---|---|---|---|
| 1 | [design_doc.md](design_doc.md) | the original strategic framing | everyone |
| 2 | [ADDENDUM.md](ADDENDUM.md) | what changed after reading the existing MEDS repos, and why; the 24-row decision log | architects, faculty |
| 3 | [specs/MEDS-S1-SPECIFICATION.md](specs/MEDS-S1-SPECIFICATION.md) | **the comprehensive spec** — architecture, block diagrams, accelerator integration, research methodology | all stakeholders |
| 4 | [specs/INTERFACES.md](specs/INTERFACES.md) | **normative** — MXIF, memory protocol, socket, RVFI, PMAs. The file that must not change. | implementers |
| 5 | [specs/SCOPE_CONTRACT.md](specs/SCOPE_CONTRACT.md) | what v1.0 does and does **not** do, with a reason for every omission. To be signed. | all, then reviewers |
| 6 | [EXECUTION_PLAN.md](EXECUTION_PLAN.md) | 22 work packages, roles, tiers, phases, staffing, risks | tech lead, contributors |
| 7 | [GITHUB_WORKFLOW.md](GITHUB_WORKFLOW.md) | repos, branches, issues, CI, reviews, releases | everyone |

### The specification as a PDF

[docs/MEDS-S1-Specification.pdf](docs/MEDS-S1-Specification.pdf) — 57 pages, typeset, with 18
purpose-drawn block, pin-out and timing diagrams plus 7 rendered flow and state diagrams. This is
the version to circulate for stakeholder review.

```
make docs        # figures + PDF
make figures     # regenerate docs/figures/*.svg only
make check-tools # verify pandoc / chrome / mmdc are present
```

**Every diagram is generated from code** ([scripts/gen_diagrams.py](scripts/gen_diagrams.py) on top
of [scripts/svgkit.py](scripts/svgkit.py)), so a design change is an edit to one file, not a hunt
through a drawing tool. Needs `python3`, `pandoc`, and Chrome/Chromium; `mmdc` is optional — without
it the mermaid diagrams are skipped and everything else still builds.

### If you only have twenty minutes

- **Faculty / external reviewer** → spec §1–5, then `ADDENDUM.md` Part E (decision log).
- **A student about to attach an accelerator** → spec §19–23 and §31–34.
- **A new contributor** → spec §1, `EXECUTION_PLAN.md` §4, `GITHUB_WORKFLOW.md` §14.
- **Someone implementing core RTL** → `INTERFACES.md`, all of it.

---

## The decisions that are expensive to reverse

Ratified or recommended; the full list with reversibility ratings is `ADDENDUM.md` Part E.

| | Decision |
|---|---|
| **Interface** | MXIF-1.0 — a documented profile of CV-X-IF, with **non-speculative issue** and **two-phase completion** (`INTERFACES.md` §1.4a) |
| **Coprocessor memory** | Physical-address, non-coherent in v1 — but the page-table walker ships with a **second port tied off** so Phase-5 translation is a drop-in |
| **Execution model** | In-order issue, out-of-order completion, in-order retire via an 8-entry completion buffer |
| **Fabric** | 256-bit AXI4 backbone, 64-bit core ports, 32-bit AXI4-Lite peripherals — sized against a declared bandwidth budget |
| **Coherence** | `Zicbom` plus an uncached DRAM alias |
| **Trace** | RVFI, plus a MEDS `rvfi_v_*` extension for vector state |
| **ISA** | RV64IMAC_Zicsr_Zifencei_Zicbom_Zicboz; M/S/U architected, S stubbed until Phase 5 |

---

## Roadmap

| Phase | Deliverable | Exit criterion |
|---|---|---|
| 0 | Specs frozen, CI green on an empty core | design review passed |
| 1 | S1-Core, CSR/traps, completion buffer, RVFI, co-simulation | RV64I arch-tests green vs Sail |
| 2 | Fabric, peripherals, generator, BSP, Verilator board | "Hello World" from C |
| 3 | Debug Module, DDR, caches, KC705 | **load and debug any ELF over JTAG, no resynthesis** |
| 4 | Accelerator socket, conformance TBs, MEDS-V adapter | **two accelerators attached by two people who did not write the core** |
| 5 | S-mode, Sv39, OpenSBI, Buildroot | shell prompt on the board |

Phase 3 is what unlocks the rest of the lab. Phase 4 is what proves this is a platform rather than a
processor.

---

## Related MEDS projects

| Repo | Relationship |
|---|---|
| [`RVV`](../RVV) — MEDS-V | the vector coprocessor; MEDS-S1's first client. Its book Ch 8.4 interface is superseded by MXIF-1.0 (erratum pending, `ADDENDUM.md` A2) |
| [`rv-workshop`](../rv-workshop) | the on-ramp. Workshop → bridge exercise → T0 contributor → thesis project |

---

## Contributing

Not yet open — the repository is pre-RTL. From Phase 0 week 6, see `GITHUB_WORKFLOW.md`.

The contribution ladder (`EXECUTION_PLAN.md` §4) runs T0 (add a peripheral via `soc.yaml`, write a
driver or a testbench) → T1 (implement a module against a frozen spec) → T2 (own a module) → T3 (own
an interface). Everyone starts at T0, including people who think they shouldn't.

---

*Copyright © 2026 Maktab-e-Digital Systems Lahore. Licensed under the Apache License, Version 2.0.*
