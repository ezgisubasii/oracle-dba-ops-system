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
| Health check | `monitoring/health_check.py` | Checks listener, connection, instance, tablespaces, blocking sessions and FRA usage. Prints Nagios-style output and exit codes |
| Container | `Dockerfile` | Packages the health check as a small Python 3.12 image |
| SLA timing | `scripts/run_incident.sh` | Runs an incident lab end to end and measures time to detect and time to resolve against SLA targets |


## Incident labs

Each incident is reproduced on purpose, diagnosed with SQL, fixed, and documented in an RCA.

| # | Incident | Error | RCA |
|---|---|---|---|
| 01 | Tablespace full | ORA-01653 | [RCA](incidents/01_tablespace_full/RCA.md) |
| 02 | Blocking session | enq: TX - row lock contention | [RCA](incidents/02_blocking_lock/RCA.md) |
| 03 | Archiver stuck | ORA-00257 | [RCA](incidents/03_archiver_stuck/RCA.md) |
| 04 | Listener down | ORA-12541 | [RCA](incidents/04_listener_down/RCA.md) |

## Health check

`monitoring/health_check.py` checks the database the way a monitoring tool would.
It prints a summary line first and exits with a Nagios status code
(0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN), so a tool like Nagios can run it as it is.

| Check | What it looks at | Thresholds |
|---|---|---|
| listener | TCP connection to port 1521 | Not reachable is CRITICAL |
| connection | Login as SYSTEM to the CDB root | Any error is CRITICAL |
| instance | Status in V$INSTANCE | Not OPEN is CRITICAL |
| tablespaces | Fullest tablespace in CDB_TABLESPACE_USAGE_METRICS | 85% WARNING, 95% CRITICAL |
| blocking | User sessions waiting for another session | Any is WARNING, 5 minutes is CRITICAL |
| fra | Fast Recovery Area usage, without reclaimable space | 80% WARNING, 90% CRITICAL |

Run it with Python

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python monitoring/health_check.py
```

Or run it as a container

```bash
docker build -t oracle-health-check .
docker run --rm --network host -v "$PWD/config.env:/app/config.env:ro" oracle-health-check
```

Example output

```
OK - all 5 checks passed
OK        listener     port 1521 is open
OK        instance     instance FREE is OPEN
OK        tablespaces  fullest is CDB$ROOT/SYSTEM is 21.8% full
OK        blocking     no blocked sessions
OK        fra          28.9% of 2048 MB used
```

### Tested against the incident labs

| Incident | During the incident | Exit code | After the fix |
|---|---|---|---|
| 01 Tablespace full | WARNING tablespaces, LAB_SMALL 90.6% full | 1 | OK, 0 |
| 02 Blocking session | WARNING blocking, 1 blocked session | 1 | OK, 0 |
| 03 Archiver stuck | CRITICAL fra at 99.2% before the database stopped, then CRITICAL connection with ORA-00257 | 2 | OK, 0 |
| 04 Listener down | CRITICAL connection, even though the port still looked open | 2 | OK, 0 |

### What I found while testing

- After the tablespace fix, CDB_TABLESPACE_USAGE_METRICS still showed the old value for a few minutes.
- With the listener down, port 1521 still looked open, because Docker listens on the port and forwards the traffic. Only a real login attempt catches this.
- oracledb 1.4 raises an OSError while it cleans up a reset connection. The script catches it and reports the original error.

## SLA timing

`scripts/run_incident.sh` runs one incident lab from start to end and measures two times.

- Time to detect, from the start of the incident until the health check reports a problem
- Time to resolve, from the start of the incident until the health check is OK again after the fix

The script compares them with the targets in `incidents/sla_targets.csv` and adds the result to `reports/sla_results.csv`.

    bash scripts/run_incident.sh 02_blocking_lock

| Incident | Priority | Detect | Resolve | Target (detect / resolve) | SLA |
|---|---|---|---|---|---|
| 01 Tablespace full | P2 | 2s | 34s | 5 min / 30 min | MET |
| 02 Blocking session | P2 | 7s | 10s | 5 min / 30 min | MET |
| 03 Archiver stuck | P1 | 1s | 35s | 5 min / 15 min | MET |
| 04 Listener down | P1 | 1s | 2s | 5 min / 15 min | MET |

These times come from automated detection with a 5 second polling interval and from
prepared runbooks. In production, the monitoring interval and the time a person needs
to react would be added to them.

## How to run

```bash
cp config.env.example config.env   # then set your own passwords
docker run -d --name oracle-dba-lab -p 1521:1521 -e ORACLE_PASSWORD=<password> gvenzl/oracle-free:23-faststart
bash scripts/setup.sh
bash scripts/refresh_schema.sh
bash scripts/enable_archivelog.sh
bash scripts/backup_rman.sh
```

## Roadmap

- [X] Incident 02: blocking session (row lock contention)
- [X] Incident 03: archiver stuck (ORA-00257)
- [X] Incident 04: listener down (ORA-12541)
- [X] Health check in Python
- [ ] SLA timing for each incident

