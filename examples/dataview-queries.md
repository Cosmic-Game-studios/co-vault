# Dataview Query Pack for co-vault

This file contains a curated set of [Dataview](https://blacksmithgu.github.io/obsidian-dataview/)
queries for use inside Obsidian. Drop them into a `dashboard.md` file at the
root of your vault to get a live dashboard of vault state.

Requires the **Dataview** Obsidian plugin (free).

---

## How to use

1. Install Dataview from Obsidian Community Plugins
2. Open your co-vault in Obsidian
3. Create a new note called `dashboard.md` at the vault root
4. Copy any of the queries below into it (inside the existing code blocks)
5. Open the note and Dataview renders live tables

The queries below work for **project vaults**. For person vault queries
see the second half.

---

# Project vault queries

## 1. Open conflicts blocking work

The single most important query — what conflicts are stopping me right now?

````markdown
```dataview
TABLE
  domain as "Domain",
  contradicts as "Contradicts",
  file.cday as "Opened"
FROM "conflicts"
WHERE status = "open"
SORT file.cday DESC
```
````

## 2. Stale proposals (no matching report)

Proposals that started but were never closed. These are uncompleted work.

````markdown
```dataview
TABLE
  task as "Task",
  domain as "Domain",
  estimated_effort as "Effort",
  file.cday as "Opened"
FROM "proposals"
WHERE !contains(file.outlinks, "reports/" + file.name)
  AND file.cday < date(today) - dur(3 days)
SORT file.cday ASC
```
````

## 3. Recent decisions I made

What architectural choices have I committed to in the last 30 days?

````markdown
```dataview
TABLE WITHOUT ID
  file.link as "Decision",
  domain as "Domain",
  status as "Status",
  file.cday as "Made on"
FROM "decisions"
WHERE author = "user"
  AND file.cday > date(today) - dur(30 days)
SORT file.cday DESC
```
````

## 4. Agent fact promotion candidates

Facts the agent has confirmed multiple times but hasn't been promoted yet.
After 3 confirmations, `bin/maintain-vault.sh` will auto-promote them.

````markdown
```dataview
TABLE
  domain,
  confirmation_count as "Confirms",
  confidence,
  last_confirmed as "Last seen"
FROM "facts"
WHERE author = "agent" AND confirmation_count >= 2
SORT confirmation_count DESC
```
````

## 5. Stale facts (need refresh or archive)

Facts that haven't been re-confirmed in 60+ days. Either re-confirm or archive.

````markdown
```dataview
TABLE
  domain,
  confidence,
  last_confirmed as "Last confirmed"
FROM "facts"
WHERE last_confirmed < date(today) - dur(60 days)
  AND author != "user"
SORT last_confirmed ASC
```
````

## 6. Reports with bad calibration (predictions wrong)

Tasks where the agent's predictions failed badly. Patterns here reveal
systematic over-confidence.

````markdown
```dataview
TABLE WITHOUT ID
  file.link as "Report",
  domain,
  predictions_correct as "✓",
  predictions_partial as "~",
  predictions_wrong as "✗",
  duration_min as "Min"
FROM "reports"
WHERE predictions_wrong >= 2
SORT predictions_wrong DESC
```
````

## 7. Domain heat map — where am I working?

Which subsystems have seen the most activity in the last 7 days?

````markdown
```dataview
TABLE length(rows) as "Activity"
FROM "reports" OR "proposals"
WHERE file.cday > date(today) - dur(7 days)
GROUP BY domain
SORT length(rows) DESC
```
````

## 8. All open follow-ups

Things noticed during work but not fixed. The follow-up backlog.

````markdown
```dataview
TASK
FROM "reports"
WHERE !completed
GROUP BY file.link
```
````

## 9. Time spent per domain

How much time has the agent spent in each subsystem?

````markdown
```dataview
TABLE WITHOUT ID
  domain as "Domain",
  sum(rows.duration_min) as "Total min",
  length(rows) as "Tasks"
FROM "reports"
WHERE duration_min
GROUP BY domain
SORT sum(rows.duration_min) DESC
```
````

## 10. Calibration trend

Reports grouped by week, showing how the agent's prediction accuracy
trends over time.

````markdown
```dataview
TABLE WITHOUT ID
  dateformat(file.cday, "yyyy-'W'ww") as "Week",
  sum(rows.predictions_correct) as "✓",
  sum(rows.predictions_partial) as "~",
  sum(rows.predictions_wrong) as "✗"
FROM "reports"
WHERE predictions_correct
GROUP BY dateformat(file.cday, "yyyy-'W'ww")
SORT rows[0].file.cday DESC
LIMIT 8
```
````

---

# Person vault queries

These work in your `$COVAULT_PERSON` vault.

## 11. Active corrections (always relevant)

Corrections are priority — they should be visible at the top of your dashboard.

````markdown
```dataview
TABLE WITHOUT ID
  file.link as "Correction",
  topic,
  severity,
  date as "Learned on"
FROM "corrections"
SORT severity DESC, date DESC
```
````

## 12. Preferences by topic

What does the agent know about how I prefer things?

````markdown
```dataview
TABLE WITHOUT ID
  topic as "Topic",
  summary as "Preference",
  confidence,
  last_confirmed as "Last seen"
FROM "preferences"
SORT topic ASC
```
````

## 13. Patterns the agent has observed

How does the agent describe my actual behavior?

````markdown
```dataview
TABLE WITHOUT ID
  topic as "Topic",
  summary as "Pattern",
  observed_count as "Times seen",
  last_observed as "Last seen"
FROM "patterns"
SORT observed_count DESC
```
````

## 14. Stale person notes (refresh or archive)

Person-vault notes that haven't been confirmed in 6 months.

````markdown
```dataview
TABLE
  topic,
  summary,
  last_confirmed
FROM "preferences" OR "patterns" OR "context"
WHERE last_confirmed < date(today) - dur(180 days)
SORT last_confirmed ASC
```
````

## 15. Low-confidence person notes

Notes the agent isn't sure about. Either confirm or remove.

````markdown
```dataview
TABLE
  topic,
  summary,
  confidence
FROM "preferences" OR "patterns" OR "context"
WHERE confidence = "low"
SORT topic ASC
```
````

---

## Tips

- **Start with queries 1, 2, and 8** for project vault — they're the most useful daily.
- **For person vault, start with query 11** — corrections are gold.
- **Combine multiple queries in one dashboard.md file** with markdown headers between them.
- **Dataview queries auto-update** when notes change. No refresh needed.
- For **plain markdown rendering** without Dataview, the queries above won't run — you'll see them as code blocks.
