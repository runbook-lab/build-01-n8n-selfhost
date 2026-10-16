# Runbook Lab Build 1 — n8n with Postgres, Caddy and restic (tested 16 Oct 2026)

Tested on Ubuntu 24.04, 2 cores, 8 GB RAM, n8n 2.43.7, Node 24.22, PostgreSQL 16.15 (Ubuntu package), Caddy 2.10.2, restic 0.18.1.

## Setup
1. Install **Node 24** first (n8n 2.43 requires `node >= 24`; on Node 22 the install fails building `isolated-vm`). Then `npm install -g n8n@2.43.7`.
2. Create a system user: `useradd --system --create-home --home-dir /srv/n8n n8n`; folders `pgdata`, `data`.
3. Secrets in `/srv/n8n/secrets.env` (chmod 600): `POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY` (generate with `openssl rand -hex 32`). **Copy the encryption key into a password manager now.**
4. Postgres as the n8n user, own data folder: `initdb -D /srv/n8n/pgdata -U n8n --auth=scram-sha-256`, start with `-c listen_addresses=127.0.0.1 -c unix_socket_directories=/srv/n8n` (without the socket setting: "could not create lock file … Permission denied"). `CREATE DATABASE n8n;`
5. `n8n.env` (no secrets) + `start-n8n.sh`. n8n listens on 127.0.0.1:5678 only; `N8N_WEBHOOK_URL` = public https address; `N8N_PROXY_HOPS=1`.
6. `Caddyfile`: domain + `reverse_proxy 127.0.0.1:5678`. Remove `tls internal` on a real public domain (Caddy then gets a Let's Encrypt certificate automatically; ports 80 and 443 must reach it).

## Backup (`backup.sh`, ~3.4 s on this build)
- `pg_dump` streamed into restic (`--stdin-from-command`), n8n folder `/srv/n8n/data`, then `forget --prune` (7 daily, 4 weekly, 6 monthly) and `restic check`.
- Use an off-server repository on a real server. Losing the restic password loses every backup.
- n8n also writes the encryption key into `/srv/n8n/data/.n8n/config`, so the backup contains the key: protect the repository password accordingly.

## Restore (tested)
1. Fresh Postgres + empty database; `restic dump latest --tag n8n-db /n8n.sql | psql …`
2. `restic restore latest --tag n8n-files` and copy `.n8n` into the new n8n folder.
3. Use the **original** `N8N_ENCRYPTION_KEY`. Without it n8n refuses to start: `Deployment key 'signing.hmac' cannot be read with this instance encryption key`.
4. Start n8n (healthy in ~4 s on this build), test a webhook that uses a credential.

## Measured
- Memory (PSS): n8n 676 MB incl. task runner · Postgres 76 MB · Caddy 50 MB → use 2 GB+ RAM.
- Webhook with header auth: 0.17 s; 200/200 sequential requests in 27 s.
- Database after 201 executions: 17 MB.
