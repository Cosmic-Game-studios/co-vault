---
type: decision
author: user
domain: auth
created: 2026-02-14T09:30Z
status: active
---

## Decision
We use stateless JWT with 15-minute access tokens. No refresh tokens.

## Why
Deploys are stateless containers. We do not want a server-side session
store. Refresh tokens would require Redis, which we explicitly do not
want in this project.

## Constraints implied
- No "remember me" feature
- Clients re-authenticate every 15 minutes
- No server-side logout (token expires naturally)
