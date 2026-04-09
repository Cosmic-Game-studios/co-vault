# Schema: decision

A `decision` is an immutable architectural or product choice.

## Frontmatter — required
| field    | type   | values                                       |
|----------|--------|----------------------------------------------|
| type     | string | `decision`                                   |
| author   | enum   | `user` \| `agent+reviewed`                   |
| domain   | string | one of the active domains                    |
| created  | string | UTC timestamp `YYYY-MM-DDTHH:MMZ`            |
| status   | enum   | `active` \| `superseded` \| `draft`          |

## Frontmatter — optional
| field          | type      | meaning                                   |
|----------------|-----------|-------------------------------------------|
| supersedes     | wikilink  | the decision this one replaces            |
| superseded_by  | wikilink  | the decision that replaced this one       |
| reviewed_by    | string    | name of the reviewer (if agent+reviewed)  |
| reviewed_at    | date      | ISO date                                  |

## Body sections
1. `## Decision` — one or two sentences stating the choice
2. `## Why` — the reasoning, in prose or bullets
3. `## Constraints implied` — what this rules out for future work

## Authority
Decisions are usually `author: user`. Agents may NEVER edit a decision
with `author: user` or `author: agent+reviewed`. If the agent observes
something that contradicts a user decision, it must open a conflict.
