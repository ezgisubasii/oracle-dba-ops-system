# RCA - ORA-00257 Archiver stuck, database closed to users

## What happened
Users could not connect to the database. Even SYSTEM got this error.

    ORA-00257: Archiver error. Connect AS SYSDBA only until resolved.

In this lab, I lowered the Fast Recovery Area (FRA) limit on purpose to
simulate a full FRA, then ran a batch job that generated a lot of redo.

## Impact
No user could connect or make changes. Only SYSDBA could connect.
The batch job hung until the problem was fixed.

## How I found the cause
1. V$RECOVERY_FILE_DEST showed the FRA at 628 MB of a 633 MB limit,
   with 0 MB reclaimable.
2. V$LOG showed both redo logs with ARCHIVED = NO, so Oracle could not reuse them.
3. The alert log (V$DIAG_ALERT_EXT) showed these errors.

       11:40:07  ORA-19809: limit exceeded for recovery files
       11:40:08  ORA-16038: log 2 sequence# cannot be archived

## Root cause
The FRA was full of archived logs that were never backed up and deleted.
The archiver could not write new archived logs, the redo logs could not be
reused, and the database stopped all new work.

## Fix
    ALTER SYSTEM SET db_recovery_file_dest_size = 2G SCOPE = BOTH;
    ALTER SYSTEM ARCHIVE LOG CURRENT;
    BACKUP AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE INPUT;

After the first command the archiver started again and SYSTEM could connect.
The RMAN backup moved the archived logs out of the FRA so it does not fill up again.

Archived logs must be deleted with RMAN, never with `rm`. Oracle keeps a record
of them, so deleting files at OS level breaks the next backup.

## Prevention
- Back up and delete archived logs on a schedule, for example every 4 hours with cron.
- Alert when FRA usage goes above 80%.
- In production, send archived log backups to a different storage, not the same disk.
- Plan large batch jobs with the DBA, so extra space can be arranged before they run.

