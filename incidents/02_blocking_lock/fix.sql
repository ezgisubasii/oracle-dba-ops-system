-- close only inactive sessions
SET SERVEROUTPUT ON
BEGIN
  FOR b IN (SELECT DISTINCT b.sid, b.serial#, b.module
              FROM v$session w
              JOIN v$session b ON b.sid = w.blocking_session
             WHERE b.status = 'INACTIVE') LOOP
    DBMS_OUTPUT.PUT_LINE('Closing session: sid=' || b.sid || ' module=' || b.module);
    EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || b.sid || ',' || b.serial# || ''' IMMEDIATE';
  END LOOP;
END;
/

--wait before closing session
EXEC DBMS_SESSION.SLEEP(3)

-- Verification, IS there any waiting session?
SELECT COUNT(*) AS blocked_sessions FROM v$session WHERE blocking_session IS NOT NULL;


