# Schema: report

A `report` is what actually happened after a proposal was executed.

## Frontmatter — required
| field         | type      | values                                          |
|---------------|-----------|-------------------------------------------------|
| type          | string    | `report`                                        |
| author        | enum      | `agent`                                         |
| status        | enum      | `done` \| `failed` \| `partial` \| `aborted`    |
| proposal      | wikilink  | the proposal this report closes                 |
| domain        | string    | same as proposal                                 |
| created       | string    | UTC timestamp                                    |
| duration_min  | integer   | minutes spent                                    |
| new_facts     | list      | wikilinks to facts created during EXECUTE       |

## Body sections
1. `## What actually happened` — honest narrative including deviations from plan
2. `## Assumptions verdict` — for each assumption: `confirmed` / `refuted` / `untested`
3. `## Follow-ups` — checklist of things noticed but not fixed
