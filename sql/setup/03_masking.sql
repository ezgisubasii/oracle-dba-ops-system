
WHENEVER SQLERROR EXIT FAILURE

-- user that have dba tools (if exist, delete and recreate)
BEGIN
  FOR u IN (SELECT username FROM dba_users WHERE username = 'DBAOPS') LOOP
    EXECUTE IMMEDIATE 'DROP USER dbaops CASCADE';
  END LOOP;
END;
/

CREATE USER dbaops NO AUTHENTICATION;
GRANT SELECT ANY TABLE, UPDATE ANY TABLE TO dbaops;

-- mask personal data in schema
CREATE OR REPLACE PROCEDURE dbaops.mask_schema (p_schema IN VARCHAR2) IS
  v_schema VARCHAR2(128) := DBMS_ASSERT.SCHEMA_NAME(UPPER(p_schema));
BEGIN
--do not change production schema
  IF v_schema LIKE 'PROD%' THEN


    RAISE_APPLICATION_ERROR(-20001, 'Production schema cannot be masked!: ' || v_schema);
  END IF;

  EXECUTE IMMEDIATE
    'UPDATE ' || v_schema || q'[.customers
        SET full_name   = 'Customer ' || customer_id,
            email       = 'user' || customer_id || '@masked.invalid',
            phone       = '+90 500 000 ' || LPAD(MOD(customer_id, 10000), 4, '0'),
            national_id = LPAD(customer_id, 11, '9')]';

  DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' line are masked: ' || v_schema || '.CUSTOMERS');
  COMMIT;
END;
/
SHOW ERRORS PROCEDURE dbaops.mask_schema



