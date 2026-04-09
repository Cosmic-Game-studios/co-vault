---
type: fact
author: agent
domain: auth
created: 2026-04-09T14:32Z
discovered_in: "[[reports/2026-04-09-1430-add-login-ui]]"
confidence: high
---

## Claim
The /login endpoint returns 401 for unknown users and 403 for wrong
passwords, leaking which usernames exist.

## Evidence
Tested with curl against the dev environment using a known username and
a random one. Different status codes confirmed across 20 requests.

## Implication
Should return identical responses (401 + same body) regardless of which
field was wrong. See [[decisions/2026-02-14-stateless-jwt]].
