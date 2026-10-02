#!/usr/bin/env bash
#Sets up the sample schema from the scratch, and runs files in sql/setup sequentially.
set -euo pipefail

CONTAINER="oracle-dba-lab"
CONN="system/Ankara06@//localhost:1521/FREEPDB1"

for f in sql/setup/*.sql; do
	echo "== $f is running"
	docker exec -i "$CONTAINER" sqlplus -s "$CONN" < "$f"
done

echo "Setup is compleated"


