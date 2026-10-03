#!/usr/bin/env bash
#Make a backup with RMAN and validate that is restorable
set -euo pipefail

CONTAINER="oracle-dba-lab"
LOG="/tmp/backup_rman.log"

docker exec -i "$CONTAINER" rman target / <<RMAN | tee "$LOG"
BACKUP AS COMPRESSED BACKUPSET DATABASE PLUS ARCHIVELOG;
DELETE NOPROMPT OBSOLETE;
RESTORE DATABASE VALIDATE;
LIST BACKUP SUMMARY;
RMAN

# error control
if grep -q "RMAN-00569" "$LOG"; then
  echo "ERROR: Backup is failed, details: $LOG"
  exit 1
fi

echo "Backup process and validation are compeleted!"



