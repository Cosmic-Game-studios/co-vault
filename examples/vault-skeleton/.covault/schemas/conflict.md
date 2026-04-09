# Schema: conflict

A `conflict` is an open contradiction the agent discovered. **It blocks
all work in the affected domain until resolved.**

## Frontmatter — required
| field          | type      | values                                |
|----------------|-----------|---------------------------------------|
| type           | string    | `conflict`                            |
| author         | enum      | `agent`                               |
| status         | enum      | `open` \| `resolved`                  |
| created        | string    | UTC timestamp                         |
| domain         | string    | the affected domain                   |
| contradicts    | wikilink  | the user note being contradicted      |
| discovered_in  | wikilink  | the report where it was found         |

## Body sections
1. `## The user's claim` — verbatim quote from the user note
2. `## What I observed` — concrete evidence
3. `## Why this matters` — consequence if unresolved
4. `## Options for resolution` — numbered options for the user to pick
