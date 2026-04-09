# Schema: proposal (v3)

A `proposal` is a hypothesis about how a task will go, written BEFORE
executing. It must contain explicit, testable predictions AND a causal
hypothesis explaining WHY the proposed approach should work.

This is grounded in **predictive coding** (Friston 2010) and enhanced
with **structured reasoning** (DeepResearch R1-R3): the agent builds
a causal model, generates predictions from it, executes, and then
measures prediction error AND hypothesis validity in the matching `report`.

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
| change_type       | enum     | see table below                       |
| risk_level        | enum     | `low` \| `medium` \| `high`           |
| prediction_count  | integer  | how many predictions in this proposal |

### Change types (from DeepResearch mutation categories)
| change_type              | level | risk   | description                                    |
|--------------------------|-------|--------|------------------------------------------------|
| `parametric`             | 1     | low    | Change a value, config, or threshold           |
| `structural_addition`    | 2     | medium | Add new function, module, endpoint             |
| `structural_removal`     | 2     | medium | Remove dead code or unnecessary complexity     |
| `structural_replacement` | 2     | high   | Replace one implementation with a better one   |
| `integration`            | 2     | medium | Connect two existing components                |
| `architectural`          | 3     | high   | Design and build a new component from scratch  |

## Body sections — required, in order
1. `## Goal` — 2-3 sentences, what success looks like
2. `## Hypothesis` — **REQUIRED, see below**
3. `## Plan` — numbered concrete steps
4. `## Predictions` — **REQUIRED, minimum 3, see below**
5. `## Alternatives considered` — **REQUIRED, see below**
6. `## Assumptions` — bulleted; if wrong, the plan is invalid
7. `## Out of scope` — files/modules that will NOT be touched

## Hypothesis format (new in v3)

The hypothesis is the causal model behind the proposal. It must contain:

```markdown
## Hypothesis
**What**: <root cause or core mechanism in one sentence>
**Why I believe this**: <evidence from ORIENT — cite vault notes>
**Falsification**: <what observation would prove this hypothesis wrong>
```

This is distinct from predictions. Predictions are measurable outcomes;
the hypothesis is the causal model that generates those predictions.
A wrong prediction updates calibration; a wrong hypothesis updates
the agent's understanding of the domain.

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

## Alternatives considered format (new in v3)

List at least one other approach that was considered and why it was rejected:

```markdown
## Alternatives considered
- **<approach name>**: <one-line description>
  Rejected because: <reason>. <cite anti-pattern if applicable>
```

This prevents "first idea = only idea" failures and creates a record
of the decision-making process for future reference.

## Confirmation rule (enhanced in v3)

Confirmation depends on BOTH effort AND risk:
- `low` risk + `small` effort → proceed immediately
- `medium` risk + `small` effort → proceed immediately
- `medium` risk + `medium` effort → wait for user confirmation
- `high` risk → ALWAYS wait for user confirmation, regardless of effort
- `large` effort → ALWAYS wait for user confirmation, regardless of risk

## Why these sections are required
Without predictions there is no calibration signal. Without the hypothesis
there is no causal learning. Without alternatives considered there is no
evidence the agent explored the solution space. The whole loop becomes
unfalsifiable without all three.
