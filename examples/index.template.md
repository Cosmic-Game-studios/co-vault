---
author: user
type: index
project: <your-project-name>
---

# <Project> co-vault

This is a shared knowledge base between me and any AI agent working on this
project. Agents must read this file first.

## Stack & ground truth
- Backend: <e.g. Go 1.23 + PostgreSQL 16 + Redis>
- Frontend: <e.g. React + Canvas>
- Hosting: <e.g. Railway>
- Repo: <path or url>

## Active domains
- [[domains/<domain-1>]]
- [[domains/<domain-2>]]

## Hard rules I (the human) care about
1. <e.g. Never use ORMs, raw SQL only>
2. <e.g. All money values in cents (int), never floats>
3. <e.g. No new dependencies without asking>

## How to find things
- User-authored ground truth: `grep -rl "author: user" .`
- Open conflicts: `ls conflicts/`
- Recent agent reports: `ls -t reports/ | head`

## Current focus
<one paragraph about what's being worked on right now>
