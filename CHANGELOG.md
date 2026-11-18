# Changelog

## v2.16 (2026-11-18)

- First release: Agent Zero v2.16 (`agent0ai/agent-zero:v2.16@sha256:0490714b…`), built from this repo so Railway can tell deployers about updates.
- Login required from the first request (`AUTH_LOGIN`, generated `AUTH_PASSWORD`); the service won't start without one.
- All user data on a volume at `/a0/usr`; health check on `/api/health`.
- Removes numpy 2.x files that reappear at runtime on Railway, so memory and knowledge work.
