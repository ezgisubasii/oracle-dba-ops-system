-- 1. Which session is waiting for which session?
SELECT w.sid AS waiter_sid, w.module AS waiter, w.event,
       ROUND(w.wait_time_micro / 1e6) AS waiting_sec,
       b.sid AS blocker_sid, b.serial# AS blocker_serial,
       b.module AS blocker, b.status AS blocker_status
  FROM v$session w
  JOIN v$session b ON b.sid = w.blocking_session
 WHERE w.blocking_session IS NOT NULL;

-- 2. The last coomand of billing_bash session
SELECT s.sql_text
  FROM v$session b
  JOIN v$sql s ON s.sql_id = b.prev_sql_id
 WHERE b.sid IN (SELECT blocking_session FROM v$session WHERE blocking_session IS NOT NULL);


