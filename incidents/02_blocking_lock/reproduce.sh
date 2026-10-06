#!/usr/bin/env bash
# update two sessions in same line, billing_batch is waiting without commit, web_checkout is waiting to billing_batch
set -euo pipefail

CONTAINER="oracle-dba-lab"
APP_CONN="prod_app/Ankara06@//localhost:1521/FREEPDB1"
DIR="$(dirname "$0")"


nohup docker exec -i "$CONTAINER" sqlplus -s "$APP_CONN" < "$DIR/billing_batch.sql" > /dev/null 2>&1 &
sleep 3
nohup docker exec -i "$CONTAINER" sqlplus -s "$APP_CONN" < "$DIR/web_checkout.sql" > /dev/null 2>&1 &
sleep 3

echo "Error is occured: web-checkout session is waiting to billing-batch lock"


