# Oracle DBA Ops System

Automating Oracle DBA work on Linux: schema setup, test refresh with
PII masking, RMAN backups with restore validation, and incident runbooks with
root cause analysis.

Runs on a CentOS 7 VM with Oracle Database 23ai Free in Docker.

## What it does

| Area | File | What it does |
|---|---|---|
| Setup | `scripts/setup.sh` | Creates the PROD_APP schema with 5,000 customers and 20,000 orders |
| Refresh | `scripts/refresh_schema.sh` | Data Pump export/import PROD_APP → TEST_APP, masks personal data, then checks row counts and that no real e-mail is left |
| Masking | `sql/setup/03_masking.sql` | PL/SQL procedure that masks PII and refuses to run on PROD schemas |
| Archivelog | `scripts/enable_archivelog.sh` | Switches the database to ARCHIVELOG mode and sets up the Fast Recovery Area |
| Backup | `scripts/backup_rman.sh` | Compressed RMAN backup, then RESTORE VALIDATE to prove it can be restored. Fails if RMAN reports an error |

## Incident labs

Each incident is reproduced on purpose, diagnosed with SQL, fixed, and documented in an RCA.

| # | Incident | Error | RCA |
|---|---|---|---|
| 01 | Tablespace full | ORA-01653 | [RCA](incidents/01_tablespace_full/RCA.md) |

## How to run

```bash
docker run -d --name oracle-dba-lab -p 1521:1521 -e ORACLE_PASSWORD=<password> gvenzl/oracle-free:23-faststart
bash scripts/setup.sh
bash scripts/refresh_schema.sh
bash scripts/enable_archivelog.sh
bash scripts/backup_rman.sh
```

## Roadmap

- [ ] Incident 02: blocking session (row lock contention)
- [ ] Incident 03: archiver stuck (ORA-00257)
- [ ] Incident 04: listener down (ORA-12541)
- [ ] Health check in Python
- [ ] SLA timing for each incident

