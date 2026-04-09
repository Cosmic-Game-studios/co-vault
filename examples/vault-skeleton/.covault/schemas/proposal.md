# Schema: proposal

A `proposal` is a plan written BEFORE executing a task.

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

## Body sections
1. `## Goal` — 2-3 sentences, what success looks like
2. `## Plan` — numbered concrete steps
3. `## Assumptions` — bulleted; if wrong, the plan is invalid
4. `## Out of scope` — files/modules that will NOT be touched

## Confirmation rule
- `small` → proceed immediately
- `medium` or `large` → wait for explicit user confirmation
