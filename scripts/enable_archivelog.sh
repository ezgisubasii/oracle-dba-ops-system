#!/usr/bin/env bash
# switch the db to archive mode, running one time, need short close
set -euo pipefail

CONTAINER="oracle-dba-lab"
FRA_DIR="/opt/oracle/oradata/fra"

docker exec "$CONTAINER" mkdir -p "$FRA_DIR"

docker exec -i "$CONTAINER" sqlplus -s / as sysdba <<SQL
WHENEVER SQLERROR EXIT FAILURE
ALTER SYSTEM SET db_recovery_file_dest_size = 4G SCOPE = BOTH;
ALTER SYSTEM SET db_recovery_file_dest = '$FRA_DIR' SCOPE = BOTH;
SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
WHENEVER SQLERROR CONTINUE
ALTER PLUGGABLE DATABASE ALL OPEN;
SELECT log_mode FROM v\$database;
SQL
