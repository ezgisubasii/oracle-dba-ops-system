#starts the listener and registers the database services with it
set -euo pipefail

source "$(git rev-parse --show-toplevel)/config.env"
CONTAINER="oracle-dba-lab"
CONN="system/${ORACLE_PASSWORD}@//localhost:1521/FREEPDB1"

docker exec "$CONTAINER" lsnrctl start

# Without this, the database registers itself with the listener only after up to 60 seconds
docker exec -i "$CONTAINER" sqlplus -s / as sysdba <<< "ALTER SYSTEM REGISTER;"

# Verify by connecting over the network
for attempt in 1 2 3 4 5 6; do
  if docker exec -i "$CONTAINER" sqlplus -s -L "$CONN" <<< "SELECT 'connected' FROM dual;" | grep -q connected; then
    echo "Clients can connect again"
    exit 0
  fi
  sleep 5
done

echo "Clients still cannot connect"
exit 1

