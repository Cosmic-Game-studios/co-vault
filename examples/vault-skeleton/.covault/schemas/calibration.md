# Schema: calibration_log.md (v3)

Aggregate calibration statistics. Auto-maintained by `bin/maintain-vault.sh`
after every report. Single file at vault root, NEVER edited by hand.

This file is the agent's own performance log. Reading it lets the agent
notice when it is over- or under-confident in its planning. Enhanced
in v3 with per-domain calibration, per-change-type calibration, and
hypothesis accuracy tracking — inspired by DeepResearch's adaptive
strategy selection.

## Frontmatter — required
| field                           | type      | meaning                              |
|---------------------------------|-----------|--------------------------------------|
| type                            | string    | `calibration`                        |
| author                          | enum      | `agent`                              |
| last_updated                    | string    | UTC timestamp                        |
| total_predictions               | integer   | lifetime count                       |
| total_correct                   | integer   | lifetime correct                     |
| total_partial                   | integer   | lifetime partial                     |
| total_wrong                     | integer   | lifetime wrong                       |
| brier_score                     | float     | mean squared error (lower = better)  |
| hypothesis_confirmed            | integer   | hypotheses proven correct            |
| hypothesis_partially_confirmed  | integer   | hypotheses partially correct         |
| hypothesis_refuted              | integer   | hypotheses proven wrong              |
| anti_patterns_recorded          | integer   | total anti-patterns in vault         |

## Body sections

### Lifetime totals
Global prediction accuracy metrics.

### Hypothesis accuracy (new in v3)
Tracks how often the agent's causal models are correct, separate from
prediction accuracy. An agent can have good predictions (what will
happen) but bad hypotheses (why it happens) — or vice versa.

### Anti-patterns recorded (new in v3)
Count of anti-pattern facts in the vault. A growing anti-pattern count
with stable prediction accuracy means the agent is learning from
mistakes and not repeating them.

### Per-domain calibration (new in v3)
```
| domain | predictions | correct | partial | wrong | accuracy |
|--------|------------|---------|---------|-------|----------|
| auth   | 47         | 41      | 4       | 2     | 87%      |
| ui     | 83         | 62      | 14      | 7     | 74%      |
```

The agent should use domain-specific accuracy (not global) when
calibrating confidence for tasks in a domain with enough history.
A domain with accuracy significantly below the global average suggests
the agent's mental model of that domain needs work.

### Per-change-type calibration (new in v3)
```
| change_type            | predictions | correct | partial | wrong | accuracy |
|------------------------|------------|---------|---------|-------|----------|
| parametric             | 20         | 18      | 1       | 1     | 90%      |
| structural_replacement | 15         | 8       | 4       | 3     | 53%      |
```

The agent should factor change-type accuracy into risk assessment.
If `structural_replacement` tasks have low accuracy, the agent should
assign lower confidence to predictions on such tasks and consider
whether a different change type could achieve the same goal.

### Confidence bucket breakdown
```
| confidence bucket | predictions | correct | partial | wrong | accuracy |
|-------------------|-------------|---------|---------|-------|----------|
| 90-100%           | 47          | 41      | 4       | 2     | 87.2%    |
| 70-89%            | 83          | 62      | 14      | 7     | 74.7%    |
```

A well-calibrated agent has accuracy ≈ confidence midpoint in each row.

## Interpretation
This file is informational only — the agent reads it on session start to
ground its prediction confidence, but never edits it directly. The
maintain script regenerates it from report data on every run.
