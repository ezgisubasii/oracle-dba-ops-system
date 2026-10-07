#!/usr/bin/env bash
# Frees the stuck archiver,restores the FRA limit, then moves archived logs into a compressed backup
set -euo pipefail

CONTAINER="oracle-dba-lab"

# 1.Give the FRA its normal limit back
docker exec -i "$CONTAINER" sqlplus -s / as sysdba <<'SQL'
WHENEVER SQLERROR EXIT FAILURE
ALTER SYSTEM SET db_recovery_file_dest_size = 2G SCOPE = BOTH;
-- Waits until the current log is archived: proves the archiver works again
ALTER SYSTEM ARCHIVE LOG CURRENT;
SQL

# 2. Long term fix, back up archived logs (compressed) and delete the originals
docker exec -i "$CONTAINER" rman target / <<'RMAN'
BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE INPUT;
RMAN

# 3. Verify it
docker exec -i "$CONTAINER" sqlplus -s / as sysdba <<'SQL'
SELECT ROUND(space_limit/1024/1024) AS limit_mb,
       ROUND(space_used/1024/1024) AS used_mb
  FROM v$recovery_file_dest;
SELECT group#, sequence#, archived, status FROM v$log;
SQL

