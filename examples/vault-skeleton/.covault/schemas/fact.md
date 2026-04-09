# Schema: fact

A `fact` is an atomic observation about the system. **One claim per file.**

## Frontmatter — required
| field          | type     | values                                |
|----------------|----------|---------------------------------------|
| type           | string   | `fact`                                |
| author         | enum     | `agent` \| `agent+reviewed` \| `user` |
| domain         | string   | one of the active domains             |
| created        | string   | UTC timestamp                         |
| confidence     | enum     | `low` \| `medium` \| `high`           |

## Frontmatter — optional
| field          | type     | meaning                               |
|----------------|----------|---------------------------------------|
| discovered_in  | wikilink | the report this fact came from        |
| superseded_by  | wikilink | newer fact that replaces this one     |

## Body sections
1. `## Claim` — ONE sentence stating the fact
2. `## Evidence` — how it was observed, concretely
3. `## Implication` — what changes for future work

## Atomicity rule
If the body contains two or more independent claims, split it into two
files. The agent must enforce this on every write.
