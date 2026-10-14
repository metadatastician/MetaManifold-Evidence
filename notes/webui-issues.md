# The open MetaManifold-WebUI issues, and what moves from this side

All five open issues on `JoshuaJewell/MetaManifold-WebUI` (read 2026-10-14) are
proposals opened by hyperpolymath. None has a comment from the maintainer yet,
and each one says explicitly that nothing is built upstream until he answers.
So the question for each is: what can be done on our side, in this repository
or on the fork, that does not pre-empt his decision and makes it easier?

| issue | waits on Joshua for | can move here now | done in this change |
| --- | --- | --- | --- |
| #27 tree viewer evidence overlay | the eight design questions, above all whether `tip:`/`split:` ids are a contract | the Julia side, which the issue places in this repository | the identifier port, a table from the viewer's own code, and measured answers to three of the questions (below) |
| #23 ALDEx2 / ANCOM-BC as `CompositionalDA.jl` | whether he wants it at all; whether a URL pin is acceptable before registration | the URL-pin question has a working example here | a draft comment pointing at it |
| #22 MN / DM regression as `CompositionalCounts.jl` | pure Julia versus `MGLM` through RCall | nothing here: the package's planned items (two more `MGLM` fixtures, the Agda proofs) are gated on its own CI | nothing to post |
| #36 move general-purpose R calls to Julia | whether "statistics through R" may be relaxed method by method | nothing without R and Julia to run parity tests against; an unapproved branch would be waste | nothing to post |
| #37 glmGamPoi dispersion | #25 settling first; RCall versus native | nothing: it names #25 as its precondition and the lock-file growth as his call | nothing to post |

## #27: what was built, and what the table says

The issue asked for a Julia port of the split-id hash with a known-answer test
against `model.ts`, and named two details that must match exactly. Both are in
`julia/src/splitid.jl`, and the known answers are not a reading of the
TypeScript: `julia/gen/splitid_kat.ts` runs `frontend/src/tree/model.ts`
itself, with bun, over seventeen trees and records every field `indexTree`
exposes (`julia/test/fixtures/splitid_kat.json`, WebUI commit `bcf52af`).
`julia/test/splitid.jl` compares every node of every case.

Three of the eight questions have measured answers now:

- **Question 2 (do reference and placement trees share ids by intent?)** On the
  fixture pair, the reference tree and a jplace over the same tips rooted
  elsewhere have identical split sets, by `model.ts` itself and by the port.
  In the pipeline the placement step is `raxmlHPC -f v -t reference.treefile -s combined.trim.fasta`
  (`src/pipeline/phylogeny.jl`): EPA keeps the given tree and only hangs
  queries on its edges, and `gappa edit accumulate` moves mass, not tips. The
  one step that can lose a sequence is trimAl with `-resoverlap/-seqoverlap`
  on the combined alignment; a reference sequence dropped there is a tree
  taxon missing from the alignment, which RAxML refuses rather than prunes.
  So the ids agree unless the run fails, and `split_difference(ref, jplace)`
  is the runtime check that turns the assumption into an assertion before an
  overlay is drawn.
- **Question 3 (attach to `placement.jplace`, `-accumulated`, or both?)** Not
  decided here, but the two files have the same reference tree and therefore
  the same `split:` ids, so a sidecar keyed by split works for either; what
  differs is the meaning of a per-clade verdict, which is the question as put.
- **Question 1 (is the id scheme a contract?)** Two properties the port had to
  copy are worth stating in the contract if it is one: names are hashed and
  ordered as UTF-16 code units (a name outside the Basic Multilingual Plane is
  two units, and the reference tip is the smallest tip key in that order,
  which is not code-point order), and the `#n` suffix follows the viewer's
  traversal, which pops the last child first, so the first repeated name in
  the file gets the highest suffix. One hazard surfaced that is not a port
  detail: a tip literally named `A#2` gets the same key as the second tip
  named `A`, the two hashes cancel in the XOR, and two branches share the id
  `0000000000000000`. It is recorded in the table and the test as the
  viewer's behaviour, not endorsed.

Not done, on purpose: the sidecar file, the overlay, and any route. Questions
4 to 8 are his, and the sidecar's shape depends on 3 and 5.

## Draft comments

### #27

> The Julia side the issue promised exists now, in MetaManifold-Evidence
> (`julia/src/splitid.jl`): `parseNewick`, `parseJplace`, `hashName` and
> `indexTree` ported one to one, tested against a table that
> `frontend/src/tree/model.ts` itself produced at `bcf52af` (seventeen trees,
> every field of `indexTree`, every node). Three things that came out of it
> bear on the questions above.
>
> On 2: on the fixture pair, the reference tree and a jplace over the same tips
> rooted elsewhere have identical split sets. In the pipeline, EPA is run with
> `-t reference.treefile` and only hangs queries on its edges, and gappa
> accumulate moves mass, not tips, so the ids agree by construction. The one
> step that can drop a sequence is trimAl's `-seqoverlap` on the combined
> alignment, and a reference dropped there is a tree taxon missing from the
> alignment, which RAxML refuses. `split_difference(ref, jplace)` is the
> runtime check I would run before drawing anything.
>
> On 1, two properties of the scheme the port had to copy, which I would write
> into the contract if it is one: names are hashed and ordered as UTF-16 code
> units (so the reference tip is the smallest key in that order, not
> code-point order), and the `#n` suffix follows the traversal, which pops the
> last child first. And one hazard: a tip literally named `A#2` gets the same
> key as the second tip named `A`, the hashes cancel, and two branches end up
> with the id `0000000000000000`. Probably nobody names a tip that way, but it
> is a silent collision, so I am flagging it rather than working around it.
>
> Nothing else is built. The sidecar's shape waits on 3 and 5.

### #23, question 2 (URL pin)

> On the URL pin: MetaManifold-Evidence does exactly this for
> `ResidualEvidenceTypes.jl`, a `[sources]` entry in `Project.toml` pinned to
> a commit (Julia ≥ 1.11), and its CI instantiates and tests from it on every
> push. The pin is one line to change when the package is registered. If that
> pattern is acceptable to you, #23's integration PR would use the same.
