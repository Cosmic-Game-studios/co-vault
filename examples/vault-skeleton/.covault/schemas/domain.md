# Schema: domain

A `domain` defines a subsystem of the project: its scope, its files,
and the rules that apply within it.

## Frontmatter — required
| field    | type     | values                              |
|----------|----------|-------------------------------------|
| type     | string   | `domain`                            |
| author   | enum     | `user`                              |
| name     | string   | short identifier (e.g. `auth`)      |
| created  | string   | UTC timestamp                       |

## Body sections
1. `## Scope` — what this domain covers
2. `## Code locations` — paths in the project repo
3. `## Ground rules` — non-negotiable constraints (the user's law)
4. `## Open questions` — things not yet decided
