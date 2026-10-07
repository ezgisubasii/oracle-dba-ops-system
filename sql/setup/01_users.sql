#If get an error, Stop continuing
WHENEVER SQLERROR EXIT FAILURE

#If user is already exist, delete user
BEGIN
	FOR u IN (SELECT username FROM dba_users WHERE username = 'PROD_APP') LOOP
		EXECUTE IMMEDIATE 'DROP USER prod_app CASCADE';
	END LOOP;
END;
/

#Production Schema for Application
CREATE USER prod_app IDENTIFIED BY "&APP_PASSWORD"
	DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;

GRANT CREATE SESSION, CREATE TABLE TO prod_app;

SELECT username, account_status, default_tablespace
	FROM dba_users
	WHERE username = 'PROD_APP';






