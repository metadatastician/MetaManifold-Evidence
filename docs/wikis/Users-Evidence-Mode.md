<!-- berrywiki
id: 01a1115e-33f9-71f9-9793-9a62391eaa25
parent: 01a1115e-33d5-7016-9f9d-1888ffbfe940
position: 30
kind: page
tags:
  - metamanifold
  - users
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Evidence Mode

Evidence Mode answers one question per taxon and sample: **given these read counts and this noise bound, is the taxon present, absent, or undecided?** The answer comes with the reason the proofs give, not a score ([Evidence README](https://github.com/metadatastician/MetaManifold-Evidence/blob/495d9a5d3e61b063dfb404608c1c076ca4cd1463/README.md)).

## What a verdict means

You choose a **noise bound** `n`, the largest number of reads by which an observed count may differ from the true (latent) count in either direction. For an observed count `y`:

| Verdict | When | Meaning |
|---|---|---|
| **entailed** (present) | `n < y` | Every true count consistent with what you saw is at least 1 |
| **refuted** (absent) | `y = 0` and `n = 0` | The only consistent true count is 0 |
| **unresolved** | `y ≤ n` and `n ≥ 1` | Some consistent true counts are 0 and some are not |

The server also returns the interval `[lo, hi] = [max(0, y − n), y + n]` of true counts consistent with the observation. Both the table and the interval are **proved** ([[Theorists-Counts-Model]]).

Two consequences are worth knowing before you choose `n`:

- Raising the noise bound **never strengthens** a verdict. An entailment can become unresolved; an unresolved verdict cannot become entailed.
- "Absent" is fragile by design. Any positive noise bound turns a zero count into **unresolved**, because a few reads could have been lost.

## How to use it today

| Part | Status |
|---|---|
| Julia server (`127.0.0.1:47613`) and its routes | **tested** against a stub of the app's query route |
| Web UI inside MetaManifold | **not yet built** (planned increment E0.4) |
| End-to-end run on the MiSeq SOP data | **not yet done** (planned increment E0.5) |

So today, Evidence Mode is used through its HTTP API, beside a running MetaManifold. See [[Developers-Evidence-Server-API]] for how to start it and call it.

## Assumptions still to confirm

1. The noise bound is an **absolute number of reads** per cell, not a proportion.
2. The true abundance is a natural number.

These are open questions for MetaManifold's maintainer. If either is wrong, the observation model changes in one place.
