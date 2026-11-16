\timing on
\echo ===== readings_pg_20 =====
SELECT count(*), avg(consumption_kwh) FROM readings_pg_20;
SELECT hour, avg(consumption_kwh) FROM readings_pg_20 GROUP BY hour ORDER BY hour;
SELECT lclid, sum(consumption_kwh) s FROM readings_pg_20 GROUP BY lclid ORDER BY s DESC LIMIT 10;
SELECT reading_date, sum(consumption_kwh) s FROM readings_pg_20 GROUP BY reading_date ORDER BY s DESC LIMIT 10;
\echo ===== readings_citus_20 =====
SELECT count(*), avg(consumption_kwh) FROM readings_citus_20;
SELECT hour, avg(consumption_kwh) FROM readings_citus_20 GROUP BY hour ORDER BY hour;
SELECT lclid, sum(consumption_kwh) s FROM readings_citus_20 GROUP BY lclid ORDER BY s DESC LIMIT 10;
SELECT reading_date, sum(consumption_kwh) s FROM readings_citus_20 GROUP BY reading_date ORDER BY s DESC LIMIT 10;
\echo ===== readings_pg_50 =====
SELECT count(*), avg(consumption_kwh) FROM readings_pg_50;
SELECT hour, avg(consumption_kwh) FROM readings_pg_50 GROUP BY hour ORDER BY hour;
SELECT lclid, sum(consumption_kwh) s FROM readings_pg_50 GROUP BY lclid ORDER BY s DESC LIMIT 10;
SELECT reading_date, sum(consumption_kwh) s FROM readings_pg_50 GROUP BY reading_date ORDER BY s DESC LIMIT 10;
\echo ===== readings_citus_50 =====
SELECT count(*), avg(consumption_kwh) FROM readings_citus_50;
SELECT hour, avg(consumption_kwh) FROM readings_citus_50 GROUP BY hour ORDER BY hour;
SELECT lclid, sum(consumption_kwh) s FROM readings_citus_50 GROUP BY lclid ORDER BY s DESC LIMIT 10;
SELECT reading_date, sum(consumption_kwh) s FROM readings_citus_50 GROUP BY reading_date ORDER BY s DESC LIMIT 10;
\echo ===== readings_pg =====
SELECT count(*), avg(consumption_kwh) FROM readings_pg;
SELECT hour, avg(consumption_kwh) FROM readings_pg GROUP BY hour ORDER BY hour;
SELECT lclid, sum(consumption_kwh) s FROM readings_pg GROUP BY lclid ORDER BY s DESC LIMIT 10;
SELECT reading_date, sum(consumption_kwh) s FROM readings_pg GROUP BY reading_date ORDER BY s DESC LIMIT 10;
\echo ===== readings_citus =====
SELECT count(*), avg(consumption_kwh) FROM readings_citus;
SELECT hour, avg(consumption_kwh) FROM readings_citus GROUP BY hour ORDER BY hour;
SELECT lclid, sum(consumption_kwh) s FROM readings_citus GROUP BY lclid ORDER BY s DESC LIMIT 10;
SELECT reading_date, sum(consumption_kwh) s FROM readings_citus GROUP BY reading_date ORDER BY s DESC LIMIT 10;

