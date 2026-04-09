# Schema: correction

Something the agent got wrong about the person and was explicitly corrected on.
THESE ARE PRIORITY NOTES — they are loaded into context on every session.

## Frontmatter — required
| field         | type   | values                              |
|---------------|--------|-------------------------------------|
| type          | string | `correction`                        |
| author        | enum   | `agent`                             |
| topic         | string | short topic key                     |
| summary       | string | ONE line — the rule learned         |
| date          | date   | when the correction happened        |
| severity      | enum   | `low` \| `medium` \| `high`         |

## Body
1. `## What I assumed` — the wrong belief
2. `## What is actually true` — the correction
3. `## How to avoid this in future` — a concrete behavioral rule

Keep under 30 lines. Rare but high-value.
