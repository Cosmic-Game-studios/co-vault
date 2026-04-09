---
type: conflict
author: agent
status: open
created: 2026-04-09T15:42Z
domain: auth
contradicts: "[[decisions/2026-02-14-stateless-jwt]]"
discovered_in: "[[reports/2026-04-09-1500-refresh-tokens]]"
---

## The user's claim
> We use stateless JWT with 15-minute access tokens. No refresh tokens.
> Deploys are stateless containers. We do not want a server-side session
> store.

## What I observed
The user just asked me to add refresh tokens. This directly contradicts
the active decision from 2026-02-14.

## Why this matters
Implementing refresh tokens would require either:
1. A Redis or Postgres-backed session store (forbidden by the decision)
2. Or storing refresh tokens client-side (defeats the security purpose)

Either path violates a deliberate architectural choice.

## Options for resolution
1. **User decision stands** → I do not implement refresh tokens. Tell me
   what to do instead.
2. **Decision is being revised** → Please edit
   `decisions/2026-02-14-stateless-jwt.md` yourself (I cannot — it is
   `author: user`). Set `status: superseded` and create a new decision.
3. **Both true under different conditions** → Split the existing decision
   into two conditional decisions (e.g. "stateless JWT for web,
   refresh tokens for mobile").
