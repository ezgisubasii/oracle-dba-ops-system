#!/usr/bin/env bash
# Runs one incident lab end to end and measures how long detection and recovery take
# Usage  bash scripts/run_incident.sh 02_blocking_lock
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
source config.env

INCIDENT="$1"
DIR="incidents/$INCIDENT"
CONN="system/${ORACLE_PASSWORD}@//localhost:1521/FREEPDB1"
RESULTS="reports/sla_results.csv"
LOG="reports/${INCIDENT}.log"
POLL_SECONDS=5
TIMEOUT_SECONDS=900

# Runs reproduce, fix or cleanup, whichever form the incident has (.sh or .sql)
run_step() {
  if [[ -f "$DIR/$1.sh" ]]; then
    bash "$DIR/$1.sh"
  elif [[ -f "$DIR/$1.sql" ]]; then
    docker exec -i oracle-dba-lab sqlplus -s "$CONN" < "$DIR/$1.sql"
  fi
}

# Prints the health check exit code (0 OK, 1 WARNING, 2 CRITICAL, 3 UNKNOWN)
health() {
  .venv/bin/python monitoring/health_check.py > /dev/null && echo 0 || echo $?
}

# Polls the health check until it reports a problem, or until it is OK again
wait_until() {
  local deadline=$(( $(date +%s) + TIMEOUT_SECONDS ))
  while (( $(date +%s) < deadline )); do
    local status
    status=$(health)
    if [[ $1 == problem && $status != 0 ]] || [[ $1 == ok && $status == 0 ]]; then
      return 0
    fi
    sleep "$POLL_SECONDS"
  done
  echo "Timed out waiting for $1" >&2
  return 1
}

mkdir -p reports
read -r PRIORITY DETECT_TARGET RESOLVE_TARGET < <(awk -F, -v id="$INCIDENT" '$1 == id {print $2, $3, $4}' incidents/sla_targets.csv)

if [[ $(health) != 0 ]]; then
  echo "The health check is not OK before the test. Fix that first."
  exit 1
fi

echo "== $INCIDENT ($PRIORITY)"
start=$(date +%s)
run_step reproduce >> "$LOG" 2>&1
wait_until problem
detected=$(date +%s)
echo "detected after $(( detected - start ))s"

run_step fix >> "$LOG" 2>&1
wait_until ok
resolved=$(date +%s)
echo "resolved after $(( resolved - start ))s"

run_step cleanup >> "$LOG" 2>&1 || true

ttd=$(( detected - start ))
ttr=$(( resolved - start ))
if (( ttd <= DETECT_TARGET && ttr <= RESOLVE_TARGET )); then sla=MET; else sla=BREACHED; fi
echo "SLA $sla (detect target ${DETECT_TARGET}s, resolve target ${RESOLVE_TARGET}s)"

[[ -f "$RESULTS" ]] || echo "date,incident,priority,detect_sec,detect_target_sec,resolve_sec,resolve_target_sec,sla" > "$RESULTS"
echo "$(date '+%Y-%m-%d %H:%M'),$INCIDENT,$PRIORITY,$ttd,$DETECT_TARGET,$ttr,$RESOLVE_TARGET,$sla" >> "$RESULTS"

