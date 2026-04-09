# Schema: calibration_log.md

Aggregate calibration statistics. Auto-maintained by `bin/maintain-vault.sh`
after every report. Single file at vault root, NEVER edited by hand.

This file is the agent's own performance log. Reading it lets the agent
notice when it is over- or under-confident in its planning.

## Frontmatter — required
| field                 | type      | meaning                              |
|-----------------------|-----------|--------------------------------------|
| type                  | string    | `calibration`                        |
| author                | enum      | `agent`                              |
| last_updated          | string    | UTC timestamp                        |
| total_predictions     | integer   | lifetime count                       |
| total_correct         | integer   | lifetime correct                     |
| total_partial         | integer   | lifetime partial                     |
| total_wrong           | integer   | lifetime wrong                       |
| brier_score           | float     | mean squared error of confidence vs outcome (lower = better) |

## Body
The body is a per-confidence-bucket breakdown:

```
| confidence bucket | predictions | correct | partial | wrong | accuracy |
|-------------------|-------------|---------|---------|-------|----------|
| 90-100%           | 47          | 41      | 4       | 2     | 87.2%    |
| 70-89%            | 83          | 62      | 14      | 7     | 74.7%    |
| 50-69%            | 31          | 18      | 8       | 5     | 58.1%    |
| <50%              | 12          | 4       | 3       | 5     | 33.3%    |
```

A well-calibrated agent has accuracy ≈ confidence midpoint in each row.
If the agent is over-confident (accuracy < confidence), it should lower
its confidence on similar future predictions.

This file is informational only — the agent reads it on session start to
ground its prediction confidence, but never edits it directly.
