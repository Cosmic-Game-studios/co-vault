# Schema: index.md

The vault entry point. Hand-curated by the user. Read by the agent on
every PHASE 1 ORIENT.

## Frontmatter — required
| field    | type     | values                              |
|----------|----------|-------------------------------------|
| type     | string   | `index`                             |
| author   | enum     | `user`                              |
| project  | string   | project name                        |

## Body sections
1. `## Stack & ground truth` — what's true about the project
2. `## Active domains` — wikilinks to all `domains/<name>` files
3. `## Hard rules I care about` — numbered list, the user's law
4. `## Current focus` — one paragraph on what's being worked on now
