#!/bin/bash
# Railway start wrapper for Agent Zero.
# - refuses to start without a web UI login (the agent runs shell commands as root)
# - gives a fresh volume its own persistent runtime id (the image ships one shared id)
# - then hands over to the upstream entrypoint (supervisord: web UI, SearXNG, cron, sshd)
set -euo pipefail

USR_DIR=/a0/usr
ENV_FILE="$USR_DIR/.env"
mkdir -p "$USR_DIR"

# Agent Zero loads /a0/usr/.env over the environment. An empty AUTH_LOGIN/AUTH_PASSWORD saved there
# (for example by clearing them under Settings) would switch the login off, so drop empty ones and let
# the Railway variables apply again.
if [ -f "$ENV_FILE" ]; then
  sed -i -E '/^[[:space:]]*AUTH_(LOGIN|PASSWORD)[[:space:]]*=[[:space:]]*("")?[[:space:]]*$/d' "$ENV_FILE"
fi

# Login check: Railway variables, or a login saved later under Settings (kept in /a0/usr/.env).
saved_login=""
if [ -f "$ENV_FILE" ]; then
  saved_login=$(sed -n 's/^[[:space:]]*AUTH_LOGIN[[:space:]]*=[[:space:]]*//p' "$ENV_FILE" | tail -n 1 | tr -d "\"'\r")
fi
if { [ -z "${AUTH_LOGIN:-}" ] || [ -z "${AUTH_PASSWORD:-}" ]; } && [ -z "$saved_login" ]; then
  echo "[railway-start] AUTH_LOGIN and AUTH_PASSWORD must both be set. Agent Zero can run any command in this" >&2
  echo "[railway-start] container, so this template does not start it without a login. Set both and redeploy." >&2
  exit 1
fi

if ! grep -q '^A0_PERSISTENT_RUNTIME_ID=' "$ENV_FILE" 2>/dev/null; then
  echo "A0_PERSISTENT_RUNTIME_ID=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')" >> "$ENV_FILE"
  echo "[railway-start] created a persistent runtime id in $ENV_FILE"
fi

exec /exe/initialize.sh "${BRANCH:-main}"
