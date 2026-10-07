--collected data loading that works at night produce a lot of redo(change)
EXEC DBMS_APPLICATION_INFO.SET_MODULE('nightly-load', 'bulk insert')


BEGIN 
	EXECUTE IMMEDIATE 'DROP TABLE prod_app.bulk_load PURGE';
EXPECTION
	WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE prod_app.bulk_load(payload VARCHAR2(4000));

BEGIN 
   FOR i IN 1 ..20 LOOP
	INSERT INTO prod_app.bulk_load SELECT RPAD('x', 4000, 'x') FROM dual CONNECT BY level <= 1000;
	DELETE FROM prod_app.bulk_load;
	COMMIT;
   END LOOP;
END;
/
EXIT 

