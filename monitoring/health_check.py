#!/usr/bin/env python3
"""Health check for the Oracle lab database."""
import os
import warnings
import sys
import socket
# Hide warning
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    import oracledb


PROJECT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
HOST = "127.0.0.1"
PORT = 1521
DSN = f"{HOST}:{PORT}/FREE"

OK, WARNING, CRITICAL, UNKNOW = 0, 1, 2, 3
STATUS_NAMES = {OK: "OK", WARNING: "WARNING", CRITICAL: "CRITICAL", UNKNOW: "UNKNOW"}
TABLESPACE_WARNING = 85
TABLESPACE_CRITICAL = 95
FRA_WARNING = 80
FRA_CRITICAL = 90
BLOCKING_CRITICAL_SECONDS = 300


def read_config(path):
    """Reads KEY=value lines from config.env into a dictionary."""
    config = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                config[key] = value
    return config


def check_listener():
    #Control Is anything accepted TCP connections on the listener port
    try:
        socket.create_connection((HOST, PORT), timeout=3).close()
    except OSError as error:
        return CRITICAL, f"port {PORT} is not reachable ({error})"
    return OK, f"port {PORT} is open"




def check_instance(cursor):
    #Control db instance is open or not
    cursor.execute("SELECT instance_name, status FROM v$instance")
    name, status = cursor.fetchone()
    if status != "OPEN":
        return CRITICAL, f"instance {name} is {status}"
    return OK, f"instance {name} is OPEN"


def main():
    config = read_config(os.path.join(PROJECT_DIR, "config.env"))
    results = [("listener", check_listener())]

    try:
        connection = oracledb.connect(user="system", password=config["ORACLE_PASSWORD"], dsn=DSN)
    except oracledb.Error as error:
        results.append(("connection", (CRITICAL, str(error))))
    else:
        with connection.cursor() as cursor:
            results.append(("instance", check_instance(cursor)))
            results.append(("tablespaces", check_tablespaces(cursor)))
            results.append(("blocking", check_blocking_sessions(cursor)))
            results.append(("fra", check_fra(cursor)))

        connection.close()

    for name, (status, message)in results:
        worst = max(status for _, (status, _) in results)
        problems = [name for name, (status, _) in results if status != OK]
        if problems:
            print(f"{STATUS_NAMES[worst]} - problem in {', '.join(problems)}")
        else:
            print(f"OK - all {len(results)} checks passed")

        for name, (status, message) in results:
            print(f"{STATUS_NAMES[status]:<9} {name:<12} {message}")

        return worst


def check_tablespaces(cursor):
    #Conltrol any tablespace is full or not
    cursor.execute("""
        SELECT c.name, m.tablespace_name, ROUND(m.used_percent, 1)
            FROM cdb_tablespace_usage_metrics m
            JOIN v$containers c ON c.con_id = m.con_id
            ORDER BY m.used_percent DESC""")
    container, tablespace, used = cursor.fetchone()
    message = f"{container}/{tablespace} is {used}% full"
    if used >= TABLESPACE_CRITICAL:
        return CRITICAL, message
    if used >= TABLESPACE_WARNING:
        return WARNING, message
    return OK, f"fullest is {message}"

def check_blocking_sessions(cursor):
    #Control is any user session waiting for a lock held by another session
    cursor.execute("""
        SELECT COUNT(*), NVL(MAX(ROUND(wait_time_micro / 1000000)), 0)
            FROM v$session
            WHERE blocking_session IS NOT NULL
            AND type = 'USER'""")
    count, longest = cursor.fetchone()
    if count == 0:
        return OK, "no blocked sessions"
    message = f"{count} blocked session, longest wait {longest}"
    if longest >= BLOCKING_CRITICAL_SECONDS:
        return CRITICAL, message
    return WARNING, message

def check_fra(cursor):
    #how full is the fast recovery area
    cursor.execute("SELECT space_limit, space_used, space_reclaimable FROM v$recovery_file_dest")
    limit, used, reclaimable = cursor.fetchone()
    if not limit:
        return WARNING, "no FRA configured"
    percent = round((used - reclaimable) / limit * 100, 1)
    message = f"{percent}% of {limit // 1024 // 1024} MB used"
    if percent >= FRA_CRITICAL:
        return CRITICAL, message
    if percent >=FRA_WARNING:
        return WARNING, message
    return OK, message    


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as error:
        print(f"UNKNOWN - health check failed ({error})")
        sys.exit(UNKNOWN)












