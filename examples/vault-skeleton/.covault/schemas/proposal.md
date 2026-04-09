# Schema: proposal (v2)

A `proposal` is a hypothesis about how a task will go, written BEFORE
executing. It must contain explicit, testable predictions.

This is grounded in **predictive coding** (Friston 2010): the agent builds
a generative model of the task's outcome, executes, and then measures
prediction error in the matching `report`.

## Frontmatter — required
| field             | type     | values                                |
|-------------------|----------|---------------------------------------|
| type              | string   | `proposal`                            |
| author            | enum     | `agent`                               |
| status            | enum     | `pending` \| `approved` \| `aborted`  |
| domain            | string   | comma-separated if multiple           |
| created           | string   | UTC timestamp                         |
| task              | string   | one-line summary of user request      |
| references        | list     | wikilinks to relevant user notes      |
| estimated_effort  | enum     | `small` \| `medium` \| `large`        |
| prediction_count  | integer  | how many predictions in this proposal |

## Body sections — required, in order
1. `## Goal` — 2-3 sentences, what success looks like
2. `## Plan` — numbered concrete steps
3. `## Predictions` — **REQUIRED, minimum 3, see below**
4. `## Assumptions` — bulleted; if wrong, the plan is invalid
5. `## Out of scope` — files/modules that will NOT be touched

## Predictions format

Each prediction is a separate line with this structure:

```
- [P<n>] confidence: <0-100>% — <testable claim>
```

Where:
- `<n>` is the prediction number (1, 2, 3, ...)
- `confidence` is the agent's calibrated probability that this prediction is correct
- The claim must be **testable** — there must be a clear way to mark it
  correct/incorrect/partial in the matching report

### Examples of GOOD predictions
- `[P1] confidence: 80% — All existing tests will pass after my changes`
- `[P2] confidence: 60% — Total task time will be under 30 minutes`
- `[P3] confidence: 90% — Will need to modify exactly these files: src/auth.go, src/auth_test.go`

### Examples of BAD predictions
- `The code will be good` (not testable)
- `Probably will work` (no confidence number)
- `User will like the result` (not measurable by the agent)

## Confirmation rule
- `small` → proceed immediately
- `medium` or `large` → wait for explicit user confirmation

## Why predictions are required
Without them there is no calibration signal. The whole loop becomes
unfalsifiable. Predictions force the agent to commit to specific claims
that can later be measured against reality.
