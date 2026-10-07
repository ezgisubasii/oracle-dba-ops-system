#!/usr/bin/env bash
# It lowers the Flash Recovery Area (FRA) limit and generates heavy changes, archiver stalls.
set -euo pipefail

CONTAINER="oracle-dba-lab"
APP_CONN="prod_app/Ankara06@//localhost:1521/FREEPDB1"
DIR="$(dirname "$0")"

# 1. lower the FRA threshold to 5 MB above my current usage (only memory)
docker exec -i "$CONTAINER" sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
SET SERVEROUTPUT ON
DECLARE
  v_limit NUMBER;
BEGIN
  SELECT space_used - space_reclaimable + 5 * 1024 * 1024 INTO v_limit FROM v$recovery_file_dest;
  EXECUTE IMMEDIATE 'ALTER SYSTEM SET db_recovery_file_dest_size = ' || v_limit || ' SCOPE = MEMORY';
  DBMS_OUTPUT.PUT_LINE('FRA limit set to ' || ROUND(v_limit / 1024 / 1024) || ' MB');
END;
/
SQL

# 2. produce redo(changes) at the background
nohup docker exec -i "$CONTAINER" sqlplus -s -L "$APP_CONN" < "$DIR/redo_generator.sql" > /dev/null 2>&1 &

echo "Redo is being generated. Run detect.sql in 1-2 minutes."

