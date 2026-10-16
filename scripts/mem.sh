#!/usr/bin/env bash
# Proportional memory (PSS) per program: counts shared memory once, unlike adding up RSS.
for pid in $(pgrep -u n8n) $(pgrep -x caddy); do
  name=$(ps -o comm= -p "$pid" | tr " " "_"); pss=$(awk '/^Pss:/ {print $2}' /proc/$pid/smaps_rollup 2>/dev/null)
  echo "$name ${pss:-0}"
done | awk '{n=$1; if (n ~ /^postgres/) n="postgres"; if (n ~ /^n8n/) n="n8n"; m[n]+=$2} END {for (k in m) printf "%-10s %5.0f MB\n", k, m[k]/1024}' | sort -k2 -nr
