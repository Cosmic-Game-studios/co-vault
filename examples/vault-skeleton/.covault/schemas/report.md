# Schema: report (v2)

A `report` is what actually happened after a proposal was executed,
including explicit verification of every prediction the proposal made.

This is the prediction-error-checking phase of the loop. The verification
data feeds the calibration log, which builds a Brier-score-like measure
of how well-calibrated the agent's predictions are over time.

## Frontmatter — required
| field         | type      | values                                          |
|---------------|-----------|-------------------------------------------------|
| type          | string    | `report`                                        |
| author        | enum      | `agent`                                         |
| status        | enum      | `done` \| `failed` \| `partial` \| `aborted`    |
| proposal      | wikilink  | the proposal this report closes                 |
| domain        | string    | same as proposal                                 |
| created       | string    | UTC timestamp                                    |
| duration_min  | integer   | minutes spent                                    |
| new_facts     | list      | wikilinks to facts created during EXECUTE       |
| predictions_correct  | integer | number of predictions marked correct       |
| predictions_partial  | integer | number marked partial                       |
| predictions_wrong    | integer | number marked wrong                         |

## Body sections — required, in order
1. `## What actually happened` — honest narrative including deviations from plan
2. `## Verification` — **REQUIRED, see format below**
3. `## Assumptions verdict` — for each assumption: `confirmed` / `refuted` / `untested`
4. `## Follow-ups` — checklist of things noticed but not fixed

## Verification format

For each prediction in the matching proposal, write one line:

```
- [P<n>] <verdict>: <one-sentence explanation>
```

Where verdict is one of:
- `correct` — prediction matched reality
- `partial` — prediction was directionally right but off in degree
- `wrong` — prediction was contradicted by reality
- `untestable` — no evidence either way (rare; usually means a bad prediction)

### Example
```
## Verification
- [P1] correct: All 47 tests passed on first run.
- [P2] wrong: Task took 52 minutes (predicted under 30).
- [P3] partial: Touched src/auth.go and src/auth_test.go as predicted, but also had to update src/middleware/require-auth.ts.
```

## Why verification is required
The calibration log uses these verdicts to compute the agent's prediction
accuracy over time. Without verification there is no learning signal.
