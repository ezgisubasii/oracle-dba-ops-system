-- Run as SYSDBA: normal users cannot connect while the archiver is stuck
PROMPT == 1. Fast Recovery Area (FRA) usage ==
SELECT ROUND(space_limit/1024/1024) AS limit_mb,
       ROUND(space_used/1024/1024) AS used_mb,
       ROUND(space_reclaimable/1024/1024) AS reclaimable_mb
  FROM v$recovery_file_dest;

PROMPT == 2. Redo logs: ARC = NO means the log could not be archived ==
SELECT group#, sequence#, archived, status FROM v$log;

PROMPT == 3. Archiver errors in the alert log ==
SELECT TO_CHAR(originating_timestamp, 'HH24:MI:SS') AS at_time,
       SUBSTR(message_text, 1, 100) AS message
  FROM v$diag_alert_ext
 WHERE originating_timestamp > SYSTIMESTAMP - INTERVAL '30' MINUTE
   AND REGEXP_LIKE(message_text, 'ORA-(19809|19804|00257|16038)')
 ORDER BY originating_timestamp DESC
 FETCH FIRST 5 ROWS ONLY;

