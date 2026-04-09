# Schema: fact (v2)

A `fact` is an atomic observation about the system. **One claim per file.**

Facts go through a CLS-style consolidation process:
- New facts start with `author: agent` and `confirmation_count: 1`
- Each time the agent re-observes the same fact, it increments the count
- When `confirmation_count >= 3`, `bin/maintain-vault.sh` auto-promotes
  the fact to `author: agent+reviewed` (becomes immutable)
- The user can also manually promote a fact at any time

This mirrors the hippocampus → neocortex transfer in human memory
(McClelland 1995): rapidly-acquired observations become slow,
stable knowledge only after repeated confirmation.

## Frontmatter — required
| field                | type     | values                                |
|----------------------|----------|---------------------------------------|
| type                 | string   | `fact`                                |
| author               | enum     | `agent` \| `agent+reviewed` \| `user` |
| domain               | string   | one of the active domains             |
| created              | string   | UTC timestamp                         |
| confidence           | enum     | `low` \| `medium` \| `high`           |
| confirmation_count   | integer  | how many times this has been re-observed (starts at 1) |
| last_confirmed       | string   | UTC timestamp of most recent confirmation |

## Frontmatter — optional
| field          | type     | meaning                               |
|----------------|----------|---------------------------------------|
| discovered_in  | wikilink | the report this fact came from        |
| superseded_by  | wikilink | newer fact that replaces this one     |
| vitality       | float    | computed by maintainer: count / days_since_last_confirmed |

## Body sections — required
1. `## Claim` — ONE sentence stating the fact
2. `## Evidence` — how it was observed, concretely
3. `## Implication` — what changes for future work

## Atomicity rule
If the body contains two or more independent claims, split it into two
files. The agent must enforce this on every write.
