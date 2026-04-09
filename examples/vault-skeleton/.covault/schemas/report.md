# Schema: report (v3)

A `report` is what actually happened after a proposal was executed,
including explicit verification of every prediction the proposal made,
a verdict on the causal hypothesis, and a structured reflection.

This is the prediction-error-checking AND learning phase of the loop.
The verification data feeds the calibration log, the hypothesis verdict
feeds domain understanding, and the reflection feeds the anti-pattern
knowledge base. Together they form the closed learning loop inspired
by **DeepResearch R3** (reflect → update model → inform future work).

## Frontmatter — required
| field                  | type      | values                                          |
|------------------------|-----------|-------------------------------------------------|
| type                   | string    | `report`                                        |
| author                 | enum      | `agent`                                         |
| status                 | enum      | `done` \| `failed` \| `partial` \| `aborted`    |
| proposal               | wikilink  | the proposal this report closes                 |
| domain                 | string    | same as proposal                                 |
| created                | string    | UTC timestamp                                    |
| change_type            | enum      | same as proposal (for calibration per type)      |
| duration_min           | integer   | minutes spent                                    |
| new_facts              | list      | wikilinks to facts created during EXECUTE       |
| anti_patterns_found    | integer   | number of anti-patterns recorded (0 if none)    |
| hypothesis_verdict     | enum      | `confirmed` \| `partially_confirmed` \| `refuted` |
| predictions_correct    | integer   | number of predictions marked correct             |
| predictions_partial    | integer   | number marked partial                            |
| predictions_wrong      | integer   | number marked wrong                              |

## Body sections — required, in order
1. `## What actually happened` — honest narrative including deviations from plan
2. `## Verification` — **REQUIRED, see format below**
3. `## Hypothesis verdict` — **REQUIRED (new in v3), see format below**
4. `## Assumptions verdict` — for each assumption: `confirmed` / `refuted` / `untested`
5. `## Reflection` — **REQUIRED (new in v3), see format below**
6. `## Follow-ups` — checklist of things noticed but not fixed

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

## Hypothesis verdict format (new in v3)

Evaluate the causal hypothesis from the matching proposal:

```markdown
## Hypothesis verdict
**Verdict**: <confirmed | partially_confirmed | refuted>
**Evidence**: <one-sentence summary of what happened vs what was hypothesized>
**Model update**: <what the agent now believes about this domain mechanism>
```

## Reflection format (new in v3 — DeepResearch R3 protocol)

Structured post-hoc analysis for compounding knowledge across tasks:

```markdown
## Reflection
**Surprises**: <outcomes not predicted at all — the unknown unknowns>
**Causal error analysis**: <for each wrong/partial prediction: WHY was it wrong,
  not just THAT it was wrong. Trace back to the assumption or knowledge gap.>
**Model update**: <what changed in the agent's understanding of this domain>
**Anti-patterns**: <approaches discovered to be counterproductive — these get
  written as anti-pattern facts in CONSOLIDATE. "None" if nothing failed.>
```

## Why these sections are required
The calibration log uses prediction verdicts to compute accuracy over time.
The hypothesis verdict builds domain understanding beyond task-specific
predictions. The reflection is the primary learning signal — without it,
the agent repeats the same mistakes across sessions. Anti-patterns prevent
the agent from wasting time on approaches that have already been proven
to fail in this project.
