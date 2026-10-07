#!/usr/bin/env bash
# Checks each layer, from the network port up to the database
source "$(git rev-parse --show-toplevel)/config.env"
CONTAINER="oracle-dba-lab"
CONN="system/${ORACLE_PASSWORD}@//localhost:1521/FREEPDB1"

echo "== 1. TCP. Is anything listening on port 1521 inside the container? =="
docker exec "$CONTAINER" bash -c 'if timeout 3 bash -c "</dev/tcp/127.0.0.1/1521" 2>/dev/null; then echo "port 1521 open"; else echo "port 1521 closed"; fi'

echo "== 2. Listener status =="
docker exec "$CONTAINER" lsnrctl status || true

echo "== 3. Client connection over the network =="
docker exec -i "$CONTAINER" sqlplus -s -L "$CONN" <<< "SELECT 'connected' FROM dual;" || true

echo "== 4. The database itself, local connection without network =="
docker exec -i "$CONTAINER" sqlplus -s / as sysdba <<< "SELECT instance_name, status FROM v\$instance;"

