# Cache-Coherency-Verification-Platform

A UVM-based verification platform for a multi-core cache coherency
protocol (MESI/MOESI) — validating snoop-based coherence across
per-core caches sharing a common memory, including the interleavings
and races that are the actual source of coherency bugs.


## Overview

- **DUT**: N-core private cache cluster (configurable core count) with
  a shared snoop bus/directory, implementing MESI (extensible to MOESI)
- **Protocol coverage**: all state transitions (M/E/S/I), snoop
  responses (HIT/HITM/MISS), bus request types (BusRd, BusRdX,
  BusUpgr, Flush/Flush'), and write-back/invalidate ordering
- **Multi-master stimulus**: independent per-core traffic generators
  producing concurrent, interleaved read/write streams to shared and
  private addresses — the actual condition that exposes coherency bugs
- **Reference model**: a golden coherence-state predictor that tracks
  the expected state of every cache line per core independently of RTL
  timing, used for scoreboard comparison
- **Data correctness checking**: end-to-end memory consistency check —
  every core's read must return the most recently written value under
  the target consistency model
- **Functional coverage**: state-transition matrix per line, snoop
  race scenarios (simultaneous BusRdX from two cores), false-sharing
  patterns, cache-to-cache transfer vs. memory-fill paths
- **Assertions (SVA)**: coherence invariants — no two caches hold a
  line Modified simultaneously, a line marked Invalid never supplies
  data, single-writer/multiple-reader property never violated

## Verification Platform Architecture

```
                ┌─────────────────────────────────────────┐
                │                Test / Env                 │
                │                                             │
   ┌────────────┼───────────┐  ┌────────────┼───────────┐   │
   │  core0_agent            │  │  core1_agent  ...        │   │
   │  ┌───────────────────┐ │  │  ┌───────────────────┐  │   │
   │  │ traffic_driver     │ │  │  │ traffic_driver     │  │   │
   │  │ (read/write seqs)  │ │  │  │ (read/write seqs)  │  │   │
   │  └─────────┬──────────┘ │  │  └─────────┬──────────┘  │   │
   │  ┌─────────▼──────────┐ │  │  ┌─────────▼──────────┐  │   │
   │  │  bus_monitor        │ │  │  │  bus_monitor        │  │   │
   │  │ (snoop/req/resp)    │ │  │  │ (snoop/req/resp)    │  │   │
   │  └─────────┬──────────┘ │  │  └─────────┬──────────┘  │   │
   └────────────┼───────────┘  └────────────┼───────────┘   │
                └──────────────┬─────────────┘                │
                               ▼                               │
                 ┌───────────────────────┐                     │
                 │  Coherence Reference   │  per-line, per-core │
                 │  Model (golden state)  │  MESI state predict │
                 └───────────┬───────────┘                     │
                             ▼                                 │
                 ┌───────────────────────┐                     │
                 │      Scoreboard        │  state + data check │
                 └───────────┬───────────┘                     │
                             ▼                                 │
                 ┌───────────────────────┐                     │
                 │  Functional Coverage   │  transitions, races,│
                 │                        │  false-sharing      │
                 └───────────────────────┘                     │
                └─────────────────────────────────────────┘
```

---

## Repository Structure

```
cache-coherency-verif/
├── README.md
├── LICENSE
├── .gitignore
├── Makefile                          # top-level: make sim / make regress / make cov
├── docs/
│   ├── coherence_protocol_spec.md    # MESI/MOESI states, transitions, bus protocol assumed
│   ├── verification_plan.md          # feature list, race scenarios, coverage model
│   ├── testplan_to_coverage_map.md   # traceability: testplan item -> covergroup/bin
│   └── env_architecture.md           # agent/env block diagram + config knobs
│
├── rtl/
│   └── dut/
│       ├── cache_core.sv             # per-core cache + FSM (MESI/MOESI states)
│       ├── snoop_bus.sv              # shared snoop bus / directory
│       └── coherence_fsm.sv
│
├── verif/
│   ├── uvm/
│   │   ├── agents/
│   │   │   └── core_agent/
│   │   │       ├── traffic_driver.sv     # drives per-core read/write requests
│   │   │       ├── bus_monitor.sv        # observes snoop req/resp on shared bus
│   │   │       ├── core_sequencer.sv
│   │   │       └── core_item.sv
│   │   ├── env/
│   │   │   ├── coherence_env.sv
│   │   │   ├── coherence_env_config.sv
│   │   │   ├── coherence_virtual_sequencer.sv
│   │   │   ├── coherence_ref_model.sv    # golden per-line, per-core state predictor
│   │   │   ├── coherence_scoreboard.sv   # state + data correctness checking
│   │   │   └── coherence_coverage.sv
│   │   ├── sequences/
│   │   │   ├── virtual_seq/
│   │   │   │   ├── base_vseq.sv
│   │   │   │   ├── shared_addr_stress_vseq.sv   # all cores hammer same lines
│   │   │   │   ├── false_sharing_vseq.sv        # adjacent-word, different-line access
│   │   │   │   ├── simultaneous_busrdx_vseq.sv  # racing write-invalidate requests
│   │   │   │   └── random_traffic_vseq.sv       # constrained-random mixed access
│   │   │   └── core_seq/
│   │   │       └── core_seq_lib.sv
│   │   └── tests/
│   │       ├── coherence_base_test.sv
│   │       ├── smoke_test.sv
│   │       ├── shared_addr_stress_test.sv
│   │       ├── false_sharing_test.sv
│   │       ├── snoop_race_test.sv
│   │       └── regression_test_list.f
│   └── sva/
│       ├── single_writer_assertions.sv    # no two caches Modified simultaneously
│       ├── invalid_no_data_assertions.sv  # Invalid line never supplies data
│       └── transition_legality_assertions.sv
│
├── sim/
│   ├── questasim/
│   │   └── run_uvm.do
│   └── vcs/
│       └── run.sh
│
├── regression/
│   ├── run_regression.py             # runs full test_list.f, seeds swept
│   ├── coverage_merge.py
│   └── report_gen.py                 # HTML pass/fail + coverage report
│
├── scripts/
│   └── waveform_gen.sh
│
└── .github/
    └── workflows/
        └── ci.yml                    # lint + smoke regression on push
```

---

