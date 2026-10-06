EXEC DBMS_APPLICATION_INFO.SET_MODULE('web-checkout', 'ship order')
UPDATE prod_app.orders SET status = 'SHIPPED' WHERE order_id = 42;
ROLLBACK;
EXIT

