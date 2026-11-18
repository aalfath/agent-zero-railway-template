[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/agent-zero-2?utm_medium=integration&utm_source=button&utm_campaign=agent-zero)

# Agent Zero on Railway

A one-click [Railway](https://railway.com) template for [Agent Zero](https://github.com/agent0ai/agent-zero) (MIT), the open-source general-purpose AI agent. It gets its own Linux environment, writes and runs code, uses a terminal, searches the web through a built-in SearXNG, keeps long-term memory and works through a chat-style web UI.

## What it deploys

- **Agent Zero v2.16**, the official image `agent0ai/agent-zero:v2.16@sha256:0490714bf25bf481ea50d59ead21acec04344cee410a86b4e159908cb92ed8a2`, pinned by version and digest and built from this repo.
- **One service** with a public HTTPS domain on the web UI (port 80) and a health check on `/api/health`.
- **One volume** on `/a0/usr`: settings, saved API keys, chats, memory, knowledge, projects, skills, scheduled tasks, uploads and the agent's work folder. It survives redeploys and updates.

## Variables

| Variable | Default | What it does |
|---|---|---|
| `AUTH_LOGIN` | `admin` | Web UI user name. |
| `AUTH_PASSWORD` | generated, 32 characters | Web UI password. Copy it from the service's Variables tab after deploying. |
| `API_KEY_OPENROUTER` | empty, optional | OpenRouter key. Agent Zero's default model preset uses OpenRouter, so with this set you can chat right away. Other providers' keys can be added under Settings. |
| `PORT` | `80` | The port Agent Zero listens on. Don't change it. |

The agent can run any command inside its container, so this template never runs it without a login: `railway-start.sh` stops the service with a clear log message if `AUTH_LOGIN` or `AUTH_PASSWORD` is empty.

## What the wrapper adds

`railway-start.sh` runs before the upstream entrypoint (`/exe/initialize.sh`):

1. Refuses to start without a login (see above), and removes empty `AUTH_LOGIN=`/`AUTH_PASSWORD=` lines from `/a0/usr/.env`, so clearing the login under Settings can't switch it off.
2. Gives a fresh volume its own `A0_PERSISTENT_RUNTIME_ID` (the upstream image ships one shared value).
3. Runs `railway-clean-venv.py`: on Railway, files that a later layer of the upstream image deletes come back at runtime (numpy 2.3.5 over numpy 1.26.4), which breaks memory and knowledge with `All ufuncs must have type numpy.ufunc`. The Dockerfile records the venv's real file list at build time, and the script removes paths that aren't in it. On a runtime without the problem it does nothing.

## Updates

New Agent Zero releases reach deployers as a Railway "update available" notice: when this repo's `main` changes (a new pinned version plus a [CHANGELOG](CHANGELOG.md) entry), Railway offers the update in your project, and you choose when to apply it. Your data stays on the volume. Read the changelog first: breaking changes are listed at the top of each entry.

Don't use Agent Zero's built-in self-update for this deployment: it changes the code inside the container, and a redeploy goes back to the image's version.

## Local test

```sh
docker build -t agent-zero-railway .
docker run -p 5080:80 -v a0_usr:/a0/usr -e AUTH_LOGIN=admin -e AUTH_PASSWORD=change-me agent-zero-railway
```

Then open http://localhost:5080.
