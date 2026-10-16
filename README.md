# Build 01 — Self-host n8n properly (Postgres · HTTPS · backups · tested restore)

Files from the Runbook Lab video **"I Self-Hosted n8n Properly, Then Restored It From Backup (It Wouldn't Start)"**.
Everything here was run on the build shown in the video (16 Oct 2026). No secrets are included.

**Tested with:** Ubuntu 24.04 · 2 cores · 8 GB RAM · n8n 2.43.7 · Node 24.22 · PostgreSQL 16.15 · Caddy 2.10.2 · restic 0.18.1

## What's here
| File | What it is |
|---|---|
| [`RUNBOOK.md`](RUNBOOK.md) | Setup, backup and the tested restore procedure, step by step |
| [`config/n8n.env`](config/n8n.env) | n8n settings (no secrets): Postgres, local-only listener, public webhook URL, proxy hops |
| [`config/secrets.env.example`](config/secrets.env.example) | Template for the database password and encryption key |
| [`config/Caddyfile`](config/Caddyfile) | HTTPS reverse proxy. Delete `tls internal` on a real public domain |
| [`config/restic-env.example`](config/restic-env.example) | Template for the backup repository settings |
| [`scripts/start-n8n.sh`](scripts/start-n8n.sh) | Starts n8n with settings + secrets |
| [`scripts/backup.sh`](scripts/backup.sh) | pg_dump → restic, n8n folder → restic, prune, check |
| [`scripts/mem.sh`](scripts/mem.sh) | Real memory use per program (PSS) |

## What broke (and the fixes)
1. **`npm install -g n8n` fails in `isolated-vm`** → n8n 2.43 requires Node ≥ 24. Install Node 24 first.
2. **Postgres: `could not create lock file … Permission denied`** → run with `-c unix_socket_directories=/srv/n8n` (your own folder).
3. **Restore without the original key: `Deployment key 'signing.hmac' cannot be read with this instance encryption key`** → n8n won't start. Keep `N8N_ENCRYPTION_KEY` in a password manager.

## Measured on this build
- Memory: n8n ≈ 676 MB (incl. task runner) · Postgres 76 MB · Caddy 50 MB → use 2 GB+ RAM
- Webhook with header auth: 0.17 s · 200/200 sequential requests in 27 s
- Backup: 3.4 s, `restic check`: no errors · Restore: healthy in 4 s
- Database after 201 executions: 17 MB

> n8n also writes the encryption key into `.n8n/config`, which is inside the backed-up folder. Protect your restic password like the server itself.

## Licence
Scripts and config in this repo: MIT. n8n itself is under the [Sustainable Use License](https://docs.n8n.io/n8n-community-license/sustainable-use-license) — read it before offering n8n to clients. Not legal advice.

Want a build like this for your business? Fixed price from £1,500, runbook included — ask in the video comments.
