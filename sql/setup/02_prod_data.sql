WHENEVER SQLERROR EXIT FAILURE

--create customers table
CREATE TABLE prod_app.customers (
  customer_id  NUMBER        PRIMARY KEY,
  full_name    VARCHAR2(100) NOT NULL,
  email        VARCHAR2(200) NOT NULL,
  phone        VARCHAR2(20),
  national_id  VARCHAR2(11),
  city         VARCHAR2(50)
);

--create orders table, each customer has an order
CREATE TABLE prod_app.orders (
  order_id     NUMBER       PRIMARY KEY,
  customer_id  NUMBER       NOT NULL REFERENCES prod_app.customers,
  amount       NUMBER(10,2) NOT NULL,
  status       VARCHAR2(20) NOT NULL,
  order_date   DATE         NOT NULL
);

--create 5000 customer
INSERT INTO prod_app.customers (customer_id, full_name, email, phone, national_id, city)
SELECT level,
       DECODE(MOD(level, 5), 0, 'Ayse', 1, 'Mehmet', 2, 'Zeynep', 3, 'Emre', 'Elif')
         || ' ' ||
       DECODE(MOD(level, 4), 0, 'Yilmaz', 1, 'Kaya', 2, 'Demir', 'Sahin'),
       'musteri' || level || '@example.com',
       '+90 5' || LPAD(MOD(level * 7919, 1000000000), 9, '0'),
       TO_CHAR(10000000000 + level * 37),
       DECODE(MOD(level, 3), 0, 'Istanbul', 1, 'Ankara', 'Izmir')
  FROM dual
CONNECT BY level <= 5000;

--create 20000 order
INSERT INTO prod_app.orders (order_id, customer_id, amount, status, order_date)
SELECT level,
       MOD(level, 5000) + 1,
       ROUND(DBMS_RANDOM.VALUE(50, 5000), 2),
       DECODE(MOD(level, 3), 0, 'NEW', 1, 'PAID', 'SHIPPED'),
       SYSDATE - MOD(level, 365)
  FROM dual
CONNECT BY level <= 20000;

COMMIT;

SELECT COUNT(*) AS customers_num FROM prod_app.customers;
SELECT COUNT(*) AS orders_num FROM prod_app.orders;
SELECT customer_id, full_name, email, city FROM prod_app.customers WHERE customer_id <= 3;



