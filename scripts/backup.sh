#!/usr/bin/env bash
# Runbook Lab Build 1 — back up n8n: database dump + n8n user folder, then prune and verify.
set -euo pipefail
source /root/.restic-env
export PATH=/opt/bin:$PATH
set -a; . /srv/n8n/secrets.env; set +a

# 1) Postgres dump streamed straight into restic. If pg_dump fails, restic refuses to save the snapshot.
restic backup --tag n8n-db --stdin-filename n8n.sql --stdin-from-command -- \
  env PGPASSWORD="$POSTGRES_PASSWORD" pg_dump -h 127.0.0.1 -U n8n -d n8n

# 2) n8n's own folder (config, binary data)
restic backup --tag n8n-files /srv/n8n/data

# 3) Keep 7 daily, 4 weekly, 6 monthly; delete the rest; check the repository
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
restic check
