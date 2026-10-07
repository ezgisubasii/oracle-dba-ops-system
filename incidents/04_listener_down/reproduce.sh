#!/usr/bin/env bash
# Stops the listener. The database keeps running, but no client can reach it over the network
set -euo pipefail

docker exec oracle-dba-lab lsnrctl stop
echo "The listener is stopped. The database itself is still running."

