#!/usr/bin/env bash
#Sets up the sample schema from the scratch, and runs files in sql/setup sequentially.
set -euo pipefail

source "$(git rev-parse --show-toplevel)/config.env"
CONTAINER="oracle-dba-lab"
CONN="system/${ORACLE_PASSWORD}@//localhost:1521/FREEPDB1"

for f in sql/setup/*.sql; do
	echo "== $f is running"


	{ echo "SET VERIFY OFF"; echo "DEFINE APP_PASSWORD = \"$APP_PASSWORD\""; cat "$f"; } | docker exec -i "$CONTAINER" sqlplus -s "$CONN"

done

echo "Setup is compleated"


