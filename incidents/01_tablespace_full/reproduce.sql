WHENEVER SQLERROR EXIT FAILURE
SET SERVEROUTPUT ON

--Clean leftover from the previous attempt if exist
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLESPACE lab_small INCLUDING CONTENTS AND DATAFILES';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- 10 MB, non expanding tablespace
CREATE TABLESPACE lab_small
  DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/lab_small01.dbf'
  SIZE 10M AUTOEXTEND OFF;

ALTER USER prod_app QUOTA UNLIMITED ON lab_small;

--continuously expanding register table
CREATE TABLE prod_app.audit_events (
  event_id  NUMBER GENERATED ALWAYS AS IDENTITY,
  payload   VARCHAR2(4000)
) TABLESPACE lab_small;

--Add data until tablespace is full
DECLARE
  e_full EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_full, -1653);
BEGIN
  LOOP
    INSERT INTO prod_app.audit_events (payload)
    SELECT RPAD('x', 4000, 'x') FROM dual CONNECT BY level <= 100;
    COMMIT;
  END LOOP;
EXCEPTION
  WHEN e_full THEN
    DBMS_OUTPUT.PUT_LINE('A fault is occured: ' || SQLERRM);
END;
/



