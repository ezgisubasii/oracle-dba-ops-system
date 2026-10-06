EXEC DBMS_APPLICATION_INFO.SET_MODULE('billing-batch', 'invoice run')
UPDATE prod_app.orders SET status = 'INVOICED' WHERE order_id = 42;
-- ERROR: COMMIT does not exist, session is waiting by keep lock
HOST sleep 900
ROLLBACK;
EXIT

