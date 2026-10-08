# RCA - ORA-01653 LAB_SMALL tablespace full

## What happened
The application could not insert into PROD_APP.AUDIT_EVENTS. Every insert failed with this error.

    ORA-01653: unable to increase tablespace LAB_SMALL by 1MB
    during insert or update on table PROD_APP.AUDIT_EVENTS

## Impact
All writes to the audit table failed. Reads and other tables were not affected.

## How I found the cause
1. DBA_TABLESPACE_USAGE_METRICS showed LAB_SMALL at 90.6% used.
2. DBA_DATA_FILES showed AUTOEXTENSIBLE = NO, so the datafile could not grow.
3. DBA_SEGMENTS showed AUDIT_EVENTS was using 3 MB of the tablespace.

The other ~6 MB is space Oracle keeps inside the datafile for its own metadata.
In this version the minimum datafile size is 784 blocks (6.1 MB).

## Root cause
The datafile was created with a fixed size of 10 MB and AUTOEXTEND OFF,
and there was no monitoring.

## Fix
    ALTER DATABASE DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/lab_small01.dbf'
      AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

The insert that failed before worked after the change. Usage dropped to 10.1%.

## Prevention
- Monitor tablespace usage and alert at 85%, before it is full.
- Use AUTOEXTEND ON with a MAXSIZE limit, never unlimited.
- Add a purge job for old audit rows so the table does not grow forever.
