# Schema: pattern

Observed behavior — how the person actually works, prompts, communicates.
Distinct from `preference` because patterns are descriptive ("this is what
they do") not normative ("this is what they want").

## Frontmatter — required
| field            | type    | values                              |
|------------------|---------|-------------------------------------|
| type             | string  | `pattern`                           |
| author           | enum    | `agent`                             |
| topic            | string  | short topic key                     |
| summary          | string  | ONE line, used in index             |
| confidence       | enum    | `low` \| `medium` \| `high`         |
| observed_count   | integer | how many times this has been seen   |
| last_observed    | date    | ISO date                            |

## Body
1. `## Pattern` — one-line description
2. `## Observations` — specific instances (dated)
3. `## Implication for agent behavior` — what should the agent DO with this

Keep under 40 lines.
