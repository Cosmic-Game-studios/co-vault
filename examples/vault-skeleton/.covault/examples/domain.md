---
type: domain
author: user
name: auth
created: 2026-02-14T09:00Z
---

## Scope
Everything related to user authentication and session management:
login, logout, token issuance, password handling, account recovery.

## Code locations
- `src/api/auth/`
- `src/lib/auth/`
- `src/pages/login.tsx`
- `src/middleware/require-auth.ts`

## Ground rules
1. Never store passwords in plain text. Use argon2id, never bcrypt.
2. Never store JWTs in localStorage. In-memory only.
3. Never add a session store. This project is stateless by design.
4. Never log full tokens, even at debug level. Log token hashes only.

## Open questions
- Should we support OAuth? (currently no)
- Multi-device session management? (currently no — each device has its own JWT)
