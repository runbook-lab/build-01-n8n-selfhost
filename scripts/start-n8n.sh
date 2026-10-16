#!/usr/bin/env bash
# Start n8n with settings + secrets (DB password is passed under n8n's own variable name)
set -a; . /srv/n8n/n8n.env; . /srv/n8n/secrets.env; set +a
export DB_POSTGRESDB_PASSWORD="$POSTGRES_PASSWORD"
export PATH=/opt/node24/package/bin:$PATH
exec n8n start
