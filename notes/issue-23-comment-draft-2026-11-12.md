Unposted draft.
Recovered from the session transcript; the file was lost from disk on 2026-11-19. Out of date since Joshua's reply on PR 70 on 2026-11-12. This session cannot confirm whether the owner posted any of it.

On URL pins: understood. No URL-pinned dependency will be added. CompositionalDA will be registered in General before any PR declares it, and that PR will carry the registry-resolved Manifest entry.

One question from my original post is still open: do you want native ALDEx2 and ANCOM-BC in MetaManifold at all? CONTRIBUTING asks for agreement in an issue first, so I will not ask you to review #70 until you answer.

If yes, this is the plan:

1. **ALDEx2 first.** Its R oracle gate compares every returned statistic with Bioconductor ALDEx2, and they agree within Monte Carlo noise. I claim parity with R, not calibration.
2. **ANCOM-BC later, as a separate PR.** A null simulation shows false-discovery inflation for small unbalanced designs (4 vs 16 samples). Bioconductor ANCOMBC shows the same inflation, so it is a property of the method, not of the port. It stays out until the package refuses designs below a bound that is fixed in advance and validated on fresh data. One simulated dataset also gives a different q-value from R, and I do not yet know why.
3. **Registration.** A human review of the package code first (General's policy for AI-assisted packages), then Registrator and the three-day wait.
4. **Rebuild #70** from current `main`: the registered version in `[deps]`, `[compat]` and `Manifest.toml`, no `renv.lock` change, ALDEx2 only, signed commits, no merge commits. I have marked #70 as a draft until then.

If no, I will close #70 and keep CompositionalDA independent.
