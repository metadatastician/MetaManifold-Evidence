<!-- berrywiki
id: 01a13ed6-34eb-7421-8c6f-892a0d3bf40f
parent: 01a1115e-346d-7569-98dd-b9e5be1b6b85
position: 150
kind: page
tags:
  - metamanifold
  - theorists
  - theory-path
archived: false
-->
<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->

# The theory path: from the R statistics to the typed augmentation

> **Draft — offered for editorial passes.** This page was drafted as a walking
> path for a reader asking the natural question: *I like this project, but is
> the mathematics safe and sound, or can it produce funny results?* Every
> section is open to edits, and the ones marked **Contribute here** are
> explicitly waiting for them. The structure — original, iteration,
> augmentation, what is built, what is ready to be minted, where it all lives —
> is the proposal; the words within it are a starting point, not a verdict.

Every claim on this page carries one of the wiki's [strength
labels](Home#how-claims-are-labelled-here). The path runs one way — from the
least to the most certain — and each part names exactly what would raise its
claims to the next label.

## Part I — The original: the R pathway

MetaManifold's statistics began, and upstream still stand, on **R through
RCall**. The theory here is *borrowed*: each method carries its properties
from its literature, and the app's own responsibility is only faithful
plumbing. That is not a weakness — it is the correct division of labour — but
it fixes the *strength of every claim* at **validated**:

| Method | What it does | Where its theory lives | Label here |
|---|---|---|---|
| `dada2` | amplicon denoising (the divisive-illumina error model) | Callahan et al. 2016, and dada2's own docs | **validated** |
| `vegan` (PERMANOVA) | between-group vs within-group variance by permutation | Anderson 2001 | **validated** |
| `MASS::glm.nb` | per-taxon negative-binomial GLM on raw counts | Venables & Ripley; the NB model itself | **validated** |
| `zCompositions::cmultRepl` | Bayesian-multiplicative zero replacement (GBM) | Martín-Fernández et al. 2003 | **validated** |
| `stats::t.test` (Welch) | two-sample t-test on CLR values | Welch 1947 and every textbook | **validated** |
| `p.adjust` (BH) | false-discovery-rate adjustment | Benjamini & Hochberg 1995 | **validated** |

"Validated" means: the method is right because the literature proved the
*method*, and the app is right because tests check that the app calls it
faithfully. See [[Theorists-Validated-vs-Proved]] for why that is a different
claim from "proved".

**Contribute here.** Each row deserves a sentence on *what* the literature
proves (e.g. PERMANOVA's exchangeability assumption, BH's FDR control under
independence) and what that proof assumes — the original pages carry these
well; this table could link to them rather than compete.

## Part II — The iteration Joshua built

[MetaManifold-WebUI](https://github.com/JoshuaJewell/MetaManifold-WebUI) is not
only plumbing. Around the borrowed methods it built *decision rules* that are
theory in their own right, pinned by tests, so their label is **tested** —
and, as Part III shows, several have since been **proved**:

- A significance test that did not run is reported differently from a null
  result — the `AlphaSignificance` status machinery (`:computed`,
  `:r_unavailable`, `:no_paired_samples`, `:test_failed`). Reporting a
  negative result that was never computed would be a *false* claim, so this
  is a correctness property of the reporting itself. **tested**
- Complete separation is refused, not reported as p≈1: with no reads in any
  sample of one group, the Wald test is undefined, and the taxon is named
  with its reason. **tested**
- The PERMANOVA p-value floor `1/(B+1)` for `B` permutations, and the rule
  that a term is withheld exactly when no within-block permutation exchanges
  its labels. **tested** (now also **proved** — Part III)
- TSS and RLE size factors centred to geometric mean 1, with the RLE refusal
  when no taxon spans every sample. **tested** (also now **proved**)
- Zero replacement bounded by `replacement_delta` against each taxon's
  smallest observed proportion. **tested**

**Contribute here.** This list is drafted from reading `main` — the
maintainer's sense of which rules are *load-bearing* may differ, and his
edits here would carry the authority of authorship.

## Part III — The type augmentation: what accommodating the types extends

The foundational work — the fork
[hyperpolymath/MetaManifold-WebUI](https://github.com/hyperpolymath/MetaManifold-WebUI),
[CompositionalDA.jl](https://github.com/hyperpolymath/CompositionalDA.jl) and
[CompositionalCounts.jl](https://github.com/hyperpolymath/CompositionalCounts.jl),
and this repository — extends the theory in one specific way: **it gives
selected program arithmetic an exact-rational model and checks properties of
that model as theorems**.

Two moves, each necessary for the other:

1. **Exact rationals instead of floating point.** Properties like "adjusted
   values are ≥ their own p-value" or "size factors are positive" are
   statements about *arithmetic*, not about the statistics. Over `Float64`
   they can be tested but never proved — rounding is always there to spoil
   a proof. Over `ℚ` (Agda's exact rationals) they become theorems about all
   inputs, no tolerance anywhere.
2. **Machine-checked proofs over that arithmetic**, under a discipline that
   keeps them honest: Agda 2.6.4.3 + stdlib 2.1, every module
   `--safe --without-K`, no postulates, no holes, no termination or
   positivity pragmas — and an audit
   (`proofs/tests/axiom-audit.sh`) that fails the build if any module is not
   reachable from the root, because an unimported module is never checked.

What is **proved** on the fork (facts measured against its `main` at
`69e9558`, 2026-10-15):

- [[Theorists-BH-and-Size-Factors]] — BH's output length, non-negativity,
  domination, monotonicity in ties and family size, the ≤ 1 envelope, and
  TSS's proportions summing to 1. The same theorems now also exist on the
  fork's `main` in `proofs/agda/`, and landed upstream as
  [PR #26](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/26)
  (merged 2026-10-07).
- **PERMANOVA's floor and withholding** (fork `proofs/agda/Permanova.agda`,
  proposed upstream as
  [PR #55](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/55)):
  `1/(B+1)` is the smallest p-value `B` permutations can give, attained
  exactly when none reaches the observed statistic, never raised by more
  permutations; and a term is withheld exactly when no within-block
  permutation exchanges its labels — the withholding rule is *forced*,
  not a policy.
- **The graded occupancy reading** (fork `docs/occupancy/`): each stage's
  measured bytes are typed to a peak in Agda (`TypedPeak.agda`,
  `GradedStages.agda`), with the HWM algebra's reclaim theorems — memory
  accounting as a typed quantity, not a log line. See the fork's
  `docs/occupancy-2026-10.adoc` for the reading.

And the discipline that keeps *proved* from leaking onto anything weaker:
[CompositionalDA.jl](https://github.com/hyperpolymath/CompositionalDA.jl)
maintains a `PROOF-STATUS.md` separating **proved** from **tested** claim by
claim, and this wiki's grid-certificate method ties Julia code to proofs the
same way ([[Theorists-Grid-Certificate-and-Mutants]]).

**Contribute here.** Part III's table of theorems is deliberately thin — the
fork's proof tree is larger than the three entries above, and a maintainer's
pass that promotes or corrects each line is exactly the editorial work this
page invites.

## Part IV — What the types make possible, and why Julia

The augmentation is not proofs-for-their-own-sake. It is what makes the
*next* layer safe to build:

- **Multinomial and Dirichlet-Multinomial regression**
  ([CompositionalCounts.jl](https://github.com/hyperpolymath/CompositionalCounts.jl))
  — compositional count models that need no pseudocount because the
  composition *is* the model; the centred effects sum to zero across taxa
  by construction. Proposed to upstream as
  [issue #22](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/22).
  Status of the MN fit: **implemented and tested**; the DM fit is **planned**.
  CLR proof sources are present under Agda `--safe --without-K`; resolve their
  status before describing the lemmas as **proved**. **not yet built** in
  MetaManifold itself.
- **Native ALDEx2 and ANCOM-BC**
  ([CompositionalDA.jl](https://github.com/hyperpolymath/CompositionalDA.jl))
  — proposed as [issue #23](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/23);
  the package separates what is proved from what is tested. **not yet built**
  in MetaManifold.
- **glmGamPoi dispersion shrinkage** — sharing information across taxa when
  estimating dispersion, proposed as
  [issue #37](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/37)
  with a pre-built implementation; the theory territory is
  Ahlmann-Eltze & Huber 2020's quasi-likelihood shrinkage. **proposed**.
- **Exact statistics** — Fisher's exact and friends over exact counts and
  rationals (fork issues #1, #3): the label this layer aims at is *proved
  on ℚ from the start*, with R kept as the oracle rather than the authority.
  **not yet built**.
- **The tree-viewer evidence overlay** — verdicts drawn on the tree: each
  branch and each placement carries *holds*, *fails* or *undecided*,
  reached from the exact statistics above and keyed by the viewer's own
  `tip:`/`split:` identifiers, so rerooting and collapsing leave every
  verdict where it was. Each verdict carries its evidence (the exact
  value as a fraction, and the proof or test behind it) and a warrant —
  the run, the config hash, the tree's `sha256` — that withdraws it when
  the tree changes rather than leaving it stale. Proposed to upstream as
  [issue #27](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/27);
  the design discussion is public, and nothing is built upstream until it
  is answered. The first increment — the Julia port of the viewer's
  identifiers, checked against the viewer's own code over twenty-one
  trees — is **tested** in this repository (`julia/src/splitid.jl`);
  the overlay itself is **not yet built**.

**Why Julia is the right home for this.** Exact rationals are first-class
(`Rational{BigInt}`), so the proved arithmetic and the runtime arithmetic can
be *the same objects*; composition is direct (an Agda-checked model, a Julia
implementation, an R oracle in one CI run); permutation workloads are fast
enough to certify behaviour on grids, which is how
[[Theorists-Grid-Certificate-and-Mutants]] ties the two together. R stays
exactly where it earned its place — the field-specific methods and the
oracle — which is what
[issue #36](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/36)
proposes to keep honest, one method at a time.

**Contribute here.** Each bullet is one theorem-shaped gap; a contributor
who writes the "what would be proved" paragraph for any of them moves its
issue from a request to a specification.

## Part V — Ready-to-mint areas

Open issues whose *mathematical territory* is already surveyed, waiting for
someone to mint the proof, the certificate, or the validated implementation.
Blank by design — claim one by opening a PR against the relevant repository
and this page:

| Area | Territory | Issue | Strongest label today |
|---|---|---|---|
| Compositional regression (MN/DM) | identifiability under a reference taxon; the offset relationship; centring across taxa | [upstream #22](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/22) | **not yet built** (package core **tested**) |
| ALDEx2 / ANCOM-BC | Dirichlet-MC zero handling; log-ratio variance tests; ANCOM-BC's bias correction | [upstream #23](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/23) | **not yet built** (package core **tested**) |
| Dispersion shrinkage | quasi-likelihood information sharing across taxa; when per-taxon θ is unstable | [upstream #37](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/37) | **proposed** (pre-built, unmerged) |
| R→Julia, one method at a time | the oracle discipline itself: validated agreement before any default switches | [upstream #36](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/36) | **validated** (first slice **proposed**) |
| Exact statistics layer | Fisher's exact, exact counts/ratios; distribution-free bounds on ℚ | [fork #1](https://github.com/hyperpolymath/MetaManifold-WebUI/issues/1), [#3](https://github.com/hyperpolymath/MetaManifold-WebUI/issues/3) | **not yet built** |
| Tree-viewer evidence overlay | the three-valued verdict algebra (**proved**); warrants and view-change no-op lemmas, small — a verdict survives rerooting because split IDs do; echo-types instances for raw↔accumulated placements, small; a general residual checker for read-count ranges (**open** — the real proof gap on this path); the reference/study noninterference statement (**open**) | [upstream #27](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/27) | first increment **tested**; overlay **not yet built** |
| Symbolic formula layer | exact manipulation of model formulas before any data is seen | [fork #4](https://github.com/hyperpolymath/MetaManifold-WebUI/issues/4) (see also [#2](https://github.com/hyperpolymath/MetaManifold-WebUI/issues/2)) | **not yet built** |
| Occupancy models | presence/absence with imperfect detection; the typed-count machinery above is the natural substrate | [fork #18](https://github.com/hyperpolymath/MetaManifold-WebUI/issues/18) | **not yet built** |
| Constrained ordinations | RDA/CCA/CAP/dbRDA as projections with provable invariance properties | [fork #19](https://github.com/hyperpolymath/MetaManifold-WebUI/issues/19) | **not yet built** |

**Contribute here.** The table is the queue. A mint means one of three
things, and the wiki's labels are the currency: an Agda proof (**proved**),
a grid certificate tying Julia to the proof (**certified on the grid**), or
a stated-tolerance agreement with a reference implementation
(**validated**).

## Part VI — The map

Where every piece of theory and its evidence live, so a reader can check
anything rather than trust this page:

| What | Where |
|---|---|
| The pipeline, the analysis methods, the decision rules | [`JoshuaJewell/MetaManifold-WebUI`](https://github.com/JoshuaJewell/MetaManifold-WebUI) (`main` at `52feb60`, 2026-10-15) |
| The proofs and the graded occupancy reading, as landed | [`hyperpolymath/MetaManifold-WebUI`](https://github.com/hyperpolymath/MetaManifold-WebUI) — `proofs/agda/`, `docs/occupancy/` (`main` at `69e9558`, 2026-10-15) |
| The BH/size-factor proofs, landed upstream | [PR #26](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/26) (merged 2026-10-07); the PERMANOVA proofs as [PR #55](https://github.com/JoshuaJewell/MetaManifold-WebUI/pull/55), open |
| Native compositional DA (ALDEx2, ANCOM-BC) | [`hyperpolymath/CompositionalDA.jl`](https://github.com/hyperpolymath/CompositionalDA.jl) — see its `proofs/PROOF-STATUS.md` |
| Multinomial / Dirichlet-Multinomial regression | [`hyperpolymath/CompositionalCounts.jl`](https://github.com/hyperpolymath/CompositionalCounts.jl) |
| Evidence Mode: proofs, grid certificates, the Julia server, the identifier port | this repository (`julia/src/splitid.jl`, `notes/webui-issues.md`) and [[Theorists]]; the overlay design as upstream [issue #27](https://github.com/JoshuaJewell/MetaManifold-WebUI/issues/27) |
| The work queue across both sides | [MetaManifold Work Board](https://github.com/users/hyperpolymath/projects/46) |

**Contribute here.** The map goes stale the way every citation does — when
either `main` moves, the pins above change, and the maintainer's eye is the
fastest way to keep them honest.

---

*This page is a walking path, not a reference: the depth lives in the pages
it links. Its purpose is that a reader who thinks "I love this idea, but is
it safe?" can see, in one pass, what is borrowed, what is tested, what is
proved, what is next — and can go and check.*
