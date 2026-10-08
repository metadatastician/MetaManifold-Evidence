<!-- berrywiki
id: 01a1115e-345b-7c10-9c65-403c3db5f7e2
parent: 01a1115e-3436-7208-8dae-d0e5a9d4534b
position: 90
kind: page
tags:
  - metamanifold
  - developers
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Evidence server API

Source: [Evidence README](https://github.com/metadatastician/MetaManifold-Evidence/blob/495d9a5d3e61b063dfb404608c1c076ca4cd1463/README.md), [`julia/src/server.jl`](https://github.com/metadatastician/MetaManifold-Evidence/blob/495d9a5d3e61b063dfb404608c1c076ca4cd1463/julia/src/server.jl). Status: **tested**, against a stub of the app's query route. It has not yet been run against a live app.

## Start it

```bash
julia --project=julia -e 'using Pkg; Pkg.instantiate()'
julia --project=julia -e 'using MetaManifoldEvidence; serve(; metamanifold_url = "http://127.0.0.1:8080")'
```

It listens on **`127.0.0.1:47613`** (`DEFAULT_PORT`), loopback only. `metamanifold_url` points at a running MetaManifold; its default port is 8080.

## Routes

| Route | Returns |
|---|---|
| `GET /api/v1/evidence/health` | The model name and the proof pins |
| `GET /api/v1/evidence/fibre?reads=y&noise=n` | The verdict and the interval `[lo, hi]` for one cell |
| `POST /api/v1/evidence/verdicts` | One verdict per taxon and sample, plus a receipt |

### `POST /api/v1/evidence/verdicts`

The body carries a `noise_bound` and **one** of:

- `table`: an inline table;
- `tsv`: a TSV string;
- `source`: `{study, run, table, group?}`, read through MetaManifold's `POST /api/v1/studies/{study}/runs/{run}/results/tables/{table}/query`.

The receipt records what was evaluated and against which proof pins (`julia/src/receipt.jl`).

## Quick check

```bash
curl -s 'http://127.0.0.1:47613/api/v1/evidence/fibre?reads=3&noise=1'
# expected by the proved closed forms: n < y, so entailed; interval [y − n, y + n] = [2, 4]
```

`count_verdict` and `fibre` in `julia/src/counts.jl` compute the answer. Their output on reads and noise 0..12 is **certified** against the Agda model. Outside that grid it is **tested**.
