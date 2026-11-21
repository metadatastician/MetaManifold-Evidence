UNPOSTED DRAFT

Codecov reports 5 uncovered patch lines on this PR: 99.53% patch coverage, 1,058 of 1,063 changed lines covered. The patch check is informational and green. The lines, at this PR's head:

| File | Line(s) | What the line is |
| --- | --- | --- |
| `src/server/routes/validated_statistics.jl` | 226-227 | the catch that rewraps a filter parse failure |
| `src/server/routes/validated_statistics.jl` | 286 | a float `time_limit_seconds` |
| `src/analysis/derived_analyses.jl` | 127 | `rethrow()` after a failed hard link with no competing record |
| `src/canonical.jl` | 220 | a `repr(::Float64)` mantissa without a decimal point, which may be unreachable |

Whether to cover them, or to leave them as they are, is your decision. If you want tests for the first three I can add them to this PR; the last one may not be reachable, and I would rather ask before testing it.
