<!-- berrywiki
id: 01a1115e-344f-7187-a537-159d5aa4ad4f
parent: 01a1115e-3436-7208-8dae-d0e5a9d4534b
position: 80
kind: page
tags:
  - metamanifold
  - developers
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# Testing

## MetaManifold-WebUI

Run the tests as CI does ([CONTRIBUTING](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/CONTRIBUTING.md#toolchain-and-pins), [README, Running tests](https://github.com/JoshuaJewell/MetaManifold-WebUI/blob/257bcdec2db0d4231ed9d5b160b5caa623485681/README.md#running-tests)):

```bash
julia --project=. -t 2 test/runtests.jl --integration --server
cd frontend && bun run test
```

- `test/runtests.jl` with no flags runs the unit tests. `--integration` adds the MiSeq SOP pipeline run; `--server` adds the HTTP smoke tests.
- Name files to run only those: `julia --project=. test/runtests.jl routes trees`.
- `CI_SKIP_TAXONOMY=1` skips taxonomy assignment in the integration run.
- The full suite loads R and every package and needs several GB of memory. On a small machine, run a few files at a time.

Tests compare computed values with known references. A test that only checks that something returned is not enough for an analysis path.

## MetaManifold-Evidence

```bash
bash scripts/fetch-layer-a.sh     # residual-evidence-types, by commit
bash scripts/check.sh             # proofs + axiom audit + expected rejections
bash scripts/mutants.sh           # 11 model corruptions; each must be refused
julia --project=julia -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
bash scripts/julia-mutants.sh     # table is current; each Julia mutant changes it
```

You need Agda **2.6.4.3**, which is what CI uses. Other versions are unchecked.

### Why the negative tests matter

A passing proof suite only means something if it can fail. That is why there are three kinds of negative test:

- `agda/reject/` holds statements that **must not** type-check, such as "entailed at `y = n`". `check.sh` requires each one to fail at its intended declaration.
- `mutants.sh` corrupts the model eleven ways and requires a refusal every time.
- `julia-mutants.sh` changes the Julia code (a non-strict threshold, a missing clamp) and requires the regenerated table to differ.

If you add a theorem, add the mutant that would make it false.
