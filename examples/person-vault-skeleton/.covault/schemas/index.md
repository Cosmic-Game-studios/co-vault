# Schema: _index.md

Auto-rebuilt by `bin/rebuild-index.sh`. The agent's primary entry point.

## Frontmatter — required
| field        | type    | values                                     |
|--------------|---------|--------------------------------------------|
| type         | string  | `index`                                    |
| author       | enum    | `agent`                                    |
| generated    | string  | UTC timestamp of last rebuild              |
| note_count   | integer | total number of notes indexed              |

## Body format
```
# Person vault index

## <folder>
- [[<folder>/<slug>]] — <summary from frontmatter>
- [[<folder>/<slug>]] — <summary>
```

The index MUST stay under 200 lines. If it grows larger, split notes,
archive stale ones, or merge duplicates.
