UNPOSTED DRAFT

DRAFT for the owner to edit and post on JuliaRegistries/General#175952. Written without seeing goerz's comment (the API refuses it from the agent session), from the list the PR 70 session passed on. Check each line against his actual words before posting, and add `[noblock]` if the reply should not itself block the merge.

---

Thank you for the review, and sorry for the stale wording at the registered commit.

What was wrong at bb3cf54: the README said "Launch review remains pending" and docs/LAUNCH-READINESS.adoc said "Registration remains on hold". Both were written before I decided to register, and they contradict the registration. [YOUR ANSWER, IN YOUR OWN WORDS: he asks whether the maintainer-review statement is real or auto-generated, citing General's LLM policy. State truthfully what you have and have not reviewed; I have not drafted this part because only you know it. Say that the code was written with AI assistance (mainly Claude, earlier work with OpenAI Codex).]

What has changed on main since:
- #19 (merged 14 Nov) rewrote both statements: the README now says v0.1.0 was submitted to General and that ANCOM-BC is experimental with no FDR-calibration claim; LAUNCH-READINESS says registration grants no certification.
- #21 adds TagBot. The repository carried two old tags (v0.1.0 and v0.2.0, from before the version was renumbered); I am deleting them so that v0.1.0 is tagged on the registered commit.
- Still to do: the repository description (it says "not yet registered"), coverage collection, and a README example for aldex2 and ancombc.

I will re-trigger the registration for v0.1.0 on the new commit once those are in place. If you would rather review the current commit as it stands, the one that matters is the commit I name in that new request. [noblock]
