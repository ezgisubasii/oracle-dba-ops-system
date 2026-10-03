#!/usr/bin/env bash
# Copy to PROD_APP schema to TEST_APP and mask personal data
set -euo pipefail

CONTAINER="oracle-dba-lab"
CONN="system/Ankara06@//localhost:1521/FREEPDB1"
SRC="PROD_APP"
TGT="TEST_APP"
DUMP="refresh_${SRC}.dmp"

echo "== 1/5 export: $SRC"
docker exec "$CONTAINER" expdp "$CONN" schemas="$SRC" directory=DATA_PUMP_DIR \
  dumpfile="$DUMP" logfile=refresh_exp.log reuse_dumpfiles=yes

echo "== 2/5 delete old $TGT"
docker exec -i "$CONTAINER" sqlplus -s "$CONN" <<SQL
WHENEVER SQLERROR EXIT FAILURE
BEGIN
  FOR u IN (SELECT username FROM dba_users WHERE username = '$TGT') LOOP
    EXECUTE IMMEDIATE 'DROP USER $TGT CASCADE';
  END LOOP;
END;
/
SQL

echo "== 3/5 import: $SRC -> $TGT"
docker exec "$CONTAINER" impdp "$CONN" directory=DATA_PUMP_DIR \
  dumpfile="$DUMP" logfile=refresh_imp.log remap_schema="$SRC:$TGT"

echo "== 4/5 masking"
docker exec -i "$CONTAINER" sqlplus -s "$CONN" <<SQL
WHENEVER SQLERROR EXIT FAILURE
SET SERVEROUTPUT ON
EXEC dbaops.mask_schema('$TGT')
SQL

echo "== 5/5 checking"
docker exec -i "$CONTAINER" sqlplus -s "$CONN" <<SQL
WHENEVER SQLERROR EXIT FAILURE
SET SERVEROUTPUT ON

DECLARE
  v_src  NUMBER;
  v_tgt  NUMBER;
  v_leak NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_src  FROM $SRC.customers;
  SELECT COUNT(*) INTO v_tgt  FROM $TGT.customers;
  SELECT COUNT(*) INTO v_leak FROM $TGT.customers WHERE email NOT LIKE '%@masked.invalid';
  DBMS_OUTPUT.PUT_LINE('source=' || v_src || ' target=' || v_tgt || ' unmasked=' || v_leak);
  IF v_src <> v_tgt OR v_leak > 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Refresh validation is unsuccessful');
  END IF;
END;
/
SQL

echo "Refresh is completed: $SRC -> $TGT"

