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
