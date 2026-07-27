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
├── Makefile                          
├── docs/
│   ├── coherence_protocol_spec.md    
│   ├── verification_plan.md
│   ├── testplan_to_coverage_map.md   
│   └── env_architecture.md           
│
├── rtl/
│   └── dut/
│       ├── cache_core.sv             )
│       ├── snoop_bus.sv              
│       └── coherence_fsm.sv
│
├── verif/
│   ├── uvm/
│   │   ├── agents/
│   │   │   └── core_agent/
│   │   │       ├── traffic_driver.sv     
│   │   │       ├── bus_monitor.sv       
│   │   │       ├── core_sequencer.sv
│   │   │       └── core_item.sv
│   │   ├── env/
│   │   │   ├── coherence_env.sv
│   │   │   ├── coherence_env_config.sv
│   │   │   ├── coherence_virtual_sequencer.sv
│   │   │   ├── coherence_ref_model.sv    r
│   │   │   ├── coherence_scoreboard.sv   
│   │   │   └── coherence_coverage.sv
│   │   ├── sequences/
│   │   │   ├── virtual_seq/
│   │   │   │   ├── base_vseq.sv
│   │   │   │   ├── shared_addr_stress_vseq.sv
│   │   │   │   ├── false_sharing_vseq.sv        
│   │   │   │   ├── simultaneous_busrdx_vseq.sv  
│   │   │   │   └── random_traffic_vseq.sv       
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
│       ├── single_writer_assertions.sv    
│       ├── invalid_no_data_assertions.sv  
│       └── transition_legality_assertions.sv
│
├── sim/
│   ├── questasim/
│   │   └── run_uvm.do
│   └── vcs/
│       └── run.sh
│
├── regression/
│   ├── run_regression.py            
│   ├── coverage_merge.py
│   └── report_gen.py                
│
├── scripts/
│   └── waveform_gen.sh
│
└── .github/
    └── workflows/
        └── ci.yml                   
```

---
## Tools

- A UVM-capable simulator (Questa/VCS) — UVM-1.2 based environment
- Python 3.10+ (regression runner, coverage/report scripts)
- GTKWave or simulator-native waveform viewer for debug


## Verification Approach

- **Testplan-driven**: every protocol feature and race scenario in
  `docs/verification_plan.md` maps to a covergroup/bin — closure is
  tracked against the plan, not just aggregate coverage percentage.
- **Reference model**: an independent per-line, per-core state
  predictor tracks expected MESI state and expected data value; the
  scoreboard compares this against RTL-observed bus transactions and
  read responses cycle-by-cycle.
- **Multi-master concurrent stimulus**: the actual differentiator —
  independent per-core sequences run concurrently against shared and
  private addresses, so the environment naturally generates racing
  snoop requests rather than relying on hand-crafted timing.
- **Directed race sequences**: on top of random traffic, specific
  known-hard scenarios are targeted directly — simultaneous BusRdX
  from two cores on the same line, false sharing across adjacent
  words in the same line, back-to-back invalidate/re-fill storms.
- **Functional coverage**: full MESI transition matrix per line,
  snoop response types (HIT/HITM/MISS), cache-to-cache transfer vs.
  memory-fill source, race scenario occurrence counts.
- **Assertions (SVA)**: structural coherence invariants that must hold
  regardless of stimulus — single-writer/multiple-reader property,
  no data supplied from an Invalid line, no illegal state transition.
- **Regression discipline**: every test runs with multiple random
  seeds in CI; coverage merged and reported against the testplan on
  every run, since coherency bugs are exactly the kind that vanish on
  seed change if not caught with breadth.
