-- Remove the bulk load table once the generator has finished
SELECT COUNT(*) AS generator_sessions FROM v$session WHERE module = 'nightly-load';
DROP TABLE prod_app.bulk_load PURGE;

