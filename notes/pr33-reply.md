# Reply for MetaManifold-WebUI#33

Status: the branch is revised and pushed. `hyperpolymath/MetaManifold-WebUI`
`fix/server-origin-hardening` now heads at `b29ff57` (was `0a66646`), so the PR
shows the new commits. This note is the reply to post on the PR; the session that
did the work can push to the fork but has no API access to Joshua's repository,
so posting it, and refreshing the PR description's verification line, is yours.

What changed on the branch:

| before | after |
| --- | --- |
| `5472148` harden server … | `eea7660` the same change, rebased on `main` at `bcf52af` |
| `c9e35b5` accept the SPA index … | `bec9c75` the same change, rebased |
| `0a66646` merge of `main` | dropped |
| | `b29ff57` docs: the Split deployment subsection |

Verified here: the merge base of the branch and `main` is the tip of `main`
(`bcf52af`); the three commits re-apply cleanly on it; the tree differs from the
old PR head in exactly two files, `test/runtests.jl` (one line, the test file
restored to the list) and `README.md` (the new subsection); every file named in
`UNIT_FILES` exists under `test/unit/`, none is listed twice, and no file there
is unlisted (38 of 38). Not verified here: the Julia suite itself. No Julia
binary of the pinned version can be fetched from this sandbox, so CI on the push
is its first run, exactly as it was for `c9e35b5`.

---

Both done, on the branch as pushed (`b29ff57`).

**Rebased.** The branch is the two original commits re-applied on `main` at
`bcf52af`, with the merge commit dropped. The `test/runtests.jl` conflict was
the `UNIT_FILES` list: #34 and #35 appended `test_permanova.jl` and
`test_write_gates.jl`, this PR appended `test_server_security.jl`. The list now
has all three. The merge commit had in fact resolved that conflict the wrong
way, keeping `main`'s two and dropping this PR's file, so the new tests were on
the branch but not run; that is the automated resolution CONTRIBUTING rules out,
and it is gone.

**Split deployment documented.** `README.md` gains the subsection you drafted,
`### Split deployment (frontend and API on different origins)`, under
Deployment after the local case. It says to set `apiBase` in
`frontend/public/config.json` to the API's address and to list the frontend's
origin in `JULIA_METAMANIFOLD_ALLOWED_ORIGINS` when starting the server, with
your example command. Two facts a reader would otherwise find out from the 403
are stated with it: an origin matches exactly, scheme and port included (so
`https://frontend.example` does not cover `http://frontend.example` or another
port, and several are comma-separated), and a page on an unlisted origin is
refused on every request that carries an `Origin` header, which is every write
and every cross-origin read. The SSH-tunnel sentence is there too, with the
reason: a browser at `http://localhost:9000` is a different origin from the
server's `http://localhost:8080`, so the tunnel port has to be listed. The row
in the environment-variable table stays as the short form.

One thing I did not do, and would rather ask about than do unasked: the tunnel
case could instead be handled in code, by treating an `Origin` that equals the
request's own `Host` (same scheme assumed) as same-origin. A tunnel would then
work without the variable. It is a small change to `_cors_middleware`, but it is
a behaviour change beyond what you asked for, so it is documented rather than
coded. Say the word and it is one commit.

Tests were not run on this push from my side; CI is its first run, as it was
for `c9e35b5`. The PR description's "CI green on `c9e35b5`" line is stale until
it is.
