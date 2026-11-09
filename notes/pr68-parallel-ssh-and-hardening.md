<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->
# PR #68 subsystem: parallel SSH, security hardening, and what "complete" means

Companion to `notes/pr68-ssh-recovery-review.md`. Everything here is about
`src/pipeline/remote_exec.jl`, `remote_session.jl`, `remote_worker.sh` and their
callers in `MetaManifold-WebUI` at PR #68 head
`5115109be0ef475b35787011e515db134f4dd05f`. Read on 2026-11-09. These are
**assessments and concrete recommendations**, not code changes: implementing
them changes the protocol, so each needs its own CI and proof run.

## 1. The shape of the system today

One call to `run_remote` is one workflow stage: one target (`host`, `base`,
`identity_file`, `threads`), one attempt directory `mm_<sha256>_<uuid>`, one
journal beside the stage log, one `flock`ed owner, one `ControlMaster` socket in
`tempdir()`, one uploaded `worker.sh` and `command.sh`, one detached workload,
and one receipt of checksum-verified outputs. Stage ordering is sequential:
DADA2's `learn_errors → denoise → chimera_removal → assign_taxonomy` and
phylogeny's `align → trim → tree` are dependencies, not independent jobs.
Parallelism today lives *inside* the remote command (`--thread`,
`r_threads`, `remote.threads`) and in the OpenSSH master, which multiplexes the
many short `ssh`/`scp` channels of one attempt over a single authenticated
connection.

`proofs/agda/MetaManifold/RemoteExecution.agda` proves `active t ≤ 1` for any
trace from a fresh attempt — "at most one live command per journal-owned
attempt" — with `duplicate-start`, `retry`, `replay` and cleanup/expiry
transitions. That invariant is the protocol, not an implementation detail.

## 2. Can it be upgraded to parallel SSH (`pssh`)?

**Not as a drop-in, and not with `pssh` as the tool.** `pssh` (parallel-ssh)
fans one command out to *many hosts*. This subsystem has one host per config
block, one command chain per stage, and a journal whose identity includes that
host and staging root. Replacing `_transport` with `pssh` would break, in
order:

1. **Authentication.** The design deliberately uses `ControlMaster=auto` +
   `ControlPersist=60` + `NumberOfPasswordPrompts=1` so a password-only
   deployment is prompted once. `pssh` opens one connection per host and would
   re-prompt (or need `sshpass`, which leaks the password into argv). The
   cancellation path reuses the live master (`_request_cancellation(...,
   connection)`) precisely because a second connection cannot answer a prompt.
2. **The single-attempt protocol.** The worker's `run.lock`, exit marker,
   `ready` marker, log offset and cleanup are all per attempt directory. A
   fan-out needs one journal per (host, stage) and a coordinator that gathers
   receipts; a single journal cannot represent N live commands, and the Agda
   `active ≤ 1` proof would become false.
3. **The barrier.** Uploads are checksum-verified (`sha256sum -c --strict`),
   then control scripts are published by atomic rename, then `ready` is
   touched. A fan-out must not start any host before *all* hosts pass that
   barrier; `pssh` has no such primitive.
4. **Cancellation and retention.** `_cancel_remote` and `_sweep` reach one host
   through one master. With N hosts, each needs its own control socket,
   cancellation tombstone and stale-attempt sweep, and a partial failure must
   not strand the other N−1 attempts.
5. **Output identity.** `_identity` includes host, base, threads, command,
   input digests and output names. A multi-host run needs a host-set identity
   and an aggregation rule for which host's output wins.
6. **The test surface.** `test/remote_ssh.jl` starts one loopback `sshd` with
   one key and one known-hosts alias. A fan-out test needs N aliases, N
   sshd instances (or one sshd with N host keys), and a deterministic partial
   failure.

`pssh` specifically is also the wrong dependency: it is a Python package, not
in the pinned tool set (`config/defaults/tool_versions.yml`), and it passes
command strings through remote shells with its own quoting rules, which would
throw away the `_sq`/`_relative`/`checked_target` guarantees this PR builds.

### Parallelism that *does* fit, in increasing order of cost

- **Already available:** keep one attempt and increase `remote.threads`, or
  let the tool use its own threading. No protocol change.
- **Stage-level concurrency:** two independent workflows already have separate
  journals and owner locks (`journal_path = abspath(log_path) * ".remote.json"`).
  A scheduler can run them concurrently over the same or different masters;
  each keeps its own `active ≤ 1` proof. This is the cheapest real upgrade.
- **Transfer concurrency:** issue the `scp` uploads/downloads on bounded
  Julia tasks over the *existing* ControlMaster, preserving the checksum
  barrier before `ready` and the all-or-nothing publish of local outputs.
  No new dependency, but `_capture` must become timeout-aware (§3, P0) and
  the fixture's `uploads`/`downloads` counters must become atomic.
- **True multi-host fan-out (a redesign, not `pssh`):** (a) add
  `remote.hosts` as an ordered list with per-host keys; (b) one journal per
  host containing `(stage, host, attempt-uuid)`, a shared run-id and a phase;
  (c) a coordinator that hashes inputs once, uploads to all hosts, verifies
  all checksums, publishes all control scripts, then launches; (d) an
  aggregate receipt that verifies every host's outputs or none; (e)
  cancellation that tombstones each host and joins; (f) an Agda model with a
  vector of attempts and a proof of "at most one live command *per host*";
  (g) a loopback fixture with N sshd aliases. Budget this as a separate PR
  with its own proof, not a change to #68.

**Recommendation:** do not upgrade #68 to `pssh`. If throughput is the goal,
use stage-level concurrency and/or bounded parallel transfers over the
existing master first; both keep the journal and the `active ≤ 1` proof intact.

## 3. Hardening this part of the system

Each item states the current behaviour, the risk, and the concrete change.
Priorities are P0 (do before merge), P1 (next hardening PR), P2 (design-level).

### P0

1. **Host key verification is delegated to the user's `known_hosts`.**
   `_transport` sets `-o ControlMaster=auto -o ControlPath=… -o
   ControlPersist=60 -o ConnectTimeout=15 -o NumberOfPasswordPrompts=1 -o
   ServerAliveInterval=10 -o ServerAliveCountMax=3`; there is no
   `StrictHostKeyChecking`, no pinned `UserKnownHostsFile`, and no
   `-o GlobalKnownHostsFile=/dev/null`. On a first connection (or a changed
   host key) an attacker can intercept the channel and answer the protocol
   probes. **Change:** accept a pinned `@hostkey` (SHA-256 fingerprint or
   full public key) in the `remote` config, write a private known-hosts file
   under the workflow directory, and add
   `-o StrictHostKeyChecking=yes -o UserKnownHostsFile=<file> -o
   GlobalKnownHostsFile=/dev/null -o HostKeyAlgorithms=…`. Fail closed on an
   unknown key rather than falling back to `yes/no`. `checked_target` already
   validates `host`/`staging_dir` as shell-safe words; extend it to validate
   the fingerprint.

2. **The locale-protocol regression is still open.** Commit `3cf7c82` dropped
   `LC_ALL=C` because wrapping `_capture`'s command in `setenv` changed argv
   and the SSH fixture rewrote the wrapper instead of `ssh`. The underlying
   concern is real: `_remote_state` parses the worker's `exit 0`, `running`,
   `ready`, `preparing`, `interrupted`, `cancelled` replies as protocol
   strings, and a translated diagnostic would be misparsed. **Change:** use
   `Base.addenv(cmd, "LC_ALL" => "C", "LANG" => "C")` (Julia ≥ 1.6) which
   sets the child environment *without* wrapping argv; additionally prefix
   the remote command itself with `LC_ALL=C LANG=C` where the worker emits
   protocol replies. Add a regression that runs the fixture with a
   non-English `LC_ALL` and asserts the state probe still parses.

3. **A hung SSH call holds the journal owner lock indefinitely.** `_capture`
   runs `cmd` with `wait=false`, then `read(out)` then `wait(p)`; there is no
   timeout. `ConnectTimeout` only bounds connection setup, not a stalled
   channel. A wedged transport blocks every later run of that stage and
   prevents `_request_cancellation` from reaching the master. **Change:**
   bound `wait(p)` with `timedwait(..., 60)`, kill the process group on
   timeout, and rethrow a distinct `RemoteTransportTimeout` so the journal is
   retained but the lock is released. Cover it with a fixture command that
   sleeps longer than the bound.

### P1

4. **Control sockets live directly in `tempdir()`.** `ctl = joinpath(tempdir(),
   "mm_$(uuid4())"` is a predictable path in a world-readable directory; SSH
   creates the socket 0600, but a pre-created path or a symlink race is still
   possible, and `ControlPersist=60` leaves the master alive after a failed
   `-O exit` (the `finally` blocks swallow that failure). **Change:** create
   a private `mktemp -d` with mode 0700, put the socket inside it, set
   `-o ControlPersist=10`, and assert the master exited (or remove the socket
   directory) in `finally`; log a warning when `-O exit` fails.

5. **Forwarding and local-command options are not disabled.** Add
   `-o ForwardAgent=no -o ClearAllForwardings=yes -o PermitLocalCommand=no
   -o AllowTcpForwarding=no -o X11Forwarding=no -o IdentitiesOnly=yes` (the
   last only when `identity_file` is set). `IdentitiesOnly` prevents an agent
   with many keys from offering the wrong one and exhausting
   `MaxAuthTries`. Keep `BatchMode=yes` only for key-based deployments; for
   password-only deployments keep `NumberOfPasswordPrompts=1` and document
   the trade-off explicitly.

6. **The journal is durable but not authenticated.** `_save_journal` fsyncs
   the file and its directory, and `_check_directory` validates the attempt
   directory name, but nothing detects a tampered journal. `_request_cancellation`
   reads `identity[2]`/`[3]`/`[5]` and `identity_file` from it and opens a
   connection to that host — a local attacker who can edit the journal can
   redirect a cancellation to a host of their choosing and make the runner
   `rm -rf` a path there. **Change:** store an HMAC (or a SHA-256 digest of
   the canonical identity plus a secret from the workflow directory) in the
   journal; verify it on every read and refuse to act on a journal whose
   digest does not match. Also validate that `identity_file` is an absolute,
   user-owned path from config, not an arbitrary string from the journal.

7. **Log replay is a log-injection channel.** `_replay_remote_log` appends
   remote bytes to the local stage log byte-for-byte so diagnostics survive
   cleanup. A compromised remote host can include ANSI escapes, fake
   `[MetaManifold] cmd:` markers, or a very large payload. **Change:** keep
   the raw bytes in a separate `.remote.log` side file, and append an escaped
   form (printable ASCII plus `\n`, control bytes as `\xNN`) to the stage log;
   cap the replay at a documented size. The idempotency test must still pass.

8. **Command strings reach a remote login shell as argv.** `_sq` and
   `_relative` are careful, but the caller-built command is still a shell
   program. **Change:** for the workload itself, upload `command.sh` (already
   done) and invoke `bash <dir>/.metamanifold/command.sh` with arguments
   passed via stdin or an uploaded manifest, rather than interpolating the
   full command into an `ssh host "…"` string. Keep `_sq` for the few paths
   that must remain words.

### P2

9. **Least privilege on the remote side.** Use a dedicated account with
   `restrict,no-pty,no-port-forwarding,no-agent-forwarding` in
   `authorized_keys`, a staging root owned by that account with mode 0700
   (`umask 077` is already set for prepare), and audit logging of
   `worker.sh` actions. Note that `noexec` on the staging mount is compatible
   with `bash worker.sh` but not with direct execution, so verify before
   enabling it.

10. **Retention and cancellation deserve explicit bounds.** `_sweep` already
    refuses symlinks, requires a worker and a >7-day exit marker, and takes
    both locks before `rm -rf`; add a remote-side `-maxdepth`/ownership check
    (`find … -user <account> -maxdepth 1`) and a per-run cap on directories
    removed. `_cancel_remote`'s `reclaim=true` deletes a directory directly
    when the worker is missing — keep that path strictly journal-owned and
    never wildcard-derived from user input.

11. **Provenance of the transport.** Record the host-key fingerprint, SSH
    version, worker checksum (`_digest(_WORKER)` is already in `_identity`)
    and control-script checksums in `Provenance.Attestation`, so a run can be
    audited after the fact.

12. **Commit signing.** The PR's three first commits are signed (`valid`), the
    remaining eight are `unsigned` (see the close-out note). `main` on the
    base repository is currently unprotected, so this is provenance, not a
    merge gate. Enable `commit.gpgsign` with a registered SSH/GPG key for
    future commits, then turn on `required_signatures` once the history is
    consistently signed. Do not force-push a rewrite of an open PR just to
    add signatures.

### What the companion patch deliberately does not do

`notes/0004-pr68-ssh-recovery-coverage.patch` changes only the
missing-output transition and its tests. Every item above changes the
transport, the journal format, the worker script or the Agda model, and
therefore needs its own loopback-SSH regression, proof run and review. Bundling
them into the coverage patch would make an already-unexecuted change impossible
to bisect. The strict CI added in *this* repository verifies that the handoff
patch is well-formed and applies to the pinned upstream commit; it does not
pretend to execute Julia that is not installed here.

## 4. Is the work complete?

- **In this repository:** yes, once PR #13 is merged. The handoff patch,
  the close-out audit, this design note, and the strict patch-integrity CI job
  are all in the branch; CI runs the Agda proofs, the Julia package tests, the
  grid-certificate mutant gate, and the new handoff checks.
- **On `MetaManifold-WebUI#68`:** not yet. Head `5115109` has four green
  checks and `mergeable_state: clean`, but three review conversations are
  still open, Codecov still reports 18 uncovered changed lines, finding 3 is
  only partly fixed at head, and the companion patch has not been pushed to
  the PR head. Resolving the threads and merging require `push`/`triage` on
  `JoshuaJewell/MetaManifold-WebUI`, which this session's token does not have
  (it has `pull` only there). The "Unverified" commit badges are signature
  status, not failed tests, and do not block anything.
- **A "fundamental issue" that arose during this work** — replay cannot
  recover a file the command never wrote — is fixed in the companion patch
  rather than papered over in the audit. The others (locale, host-key pinning,
  transport timeout, journal authentication) are recorded above with
  priorities so they are not silently lost.
