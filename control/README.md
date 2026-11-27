# Control files for work sent to JoshuaJewell/MetaManifold-WebUI

These files exist because the same review requests came back 3 times. Every
session reported "done" from its own task list. No session compared the
maintainer's comments with the live branch.

| File | What it is | Who may change it |
| --- | --- | --- |
| `worker-brief.md` | the 1-page brief every session reads before work on these pull requests | the owner |
| `rulings.md` | every owner ruling, dated, in the owner's words. A ruling that is not here does not exist. | the owner. A session may add a row only with the state `proposed`. |
| `requests.md` | every request from the maintainer, with the evidence that answers it | any session, under the rules in the file |
| `pre-push-upstream.sh` | a git pre-push gate for the fork branches that feed the maintainer | the owner |
| `test-pre-push-upstream.sh` | its self-check: `bash control/test-pre-push-upstream.sh` | with the gate |

The gate is the weakest form of the control that works. A session can skip a
local hook. A ruleset on the fork branches cannot be skipped. Only the owner
can set one.
