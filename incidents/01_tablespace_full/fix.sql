WHENEVER SQLERROR EXIT FAILURE

-- Allow file expanding, butput the upper limit 
ALTER DATABASE DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/lab_small01.dbf'
  AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

-- Validation: Does the addition that previosly failed work?
INSERT INTO prod_app.audit_events (payload)
SELECT RPAD('x', 4000, 'x') FROM dual CONNECT BY level <= 100;
COMMIT;

SELECT tablespace_name, ROUND(used_percent, 1) AS used_pct
  FROM dba_tablespace_usage_metrics
 WHERE tablespace_name = 'LAB_SMALL';

