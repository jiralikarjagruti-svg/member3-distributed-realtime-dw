CREATE TABLE readings_pg_20 AS SELECT * FROM readings_pg WHERE random() < 0.2;
CREATE TABLE readings_pg_50 AS SELECT * FROM readings_pg WHERE random() < 0.5;

CREATE TABLE readings_citus_20 (LIKE readings_pg);
SELECT create_distributed_table('readings_citus_20', 'lclid');
INSERT INTO readings_citus_20 SELECT * FROM readings_pg_20;

CREATE TABLE readings_citus_50 (LIKE readings_pg);
SELECT create_distributed_table('readings_citus_50', 'lclid');
INSERT INTO readings_citus_50 SELECT * FROM readings_pg_50;

SELECT 'pg_20' t, count(*) FROM readings_pg_20
UNION ALL SELECT 'citus_20', count(*) FROM readings_citus_20
UNION ALL SELECT 'pg_50', count(*) FROM readings_pg_50
UNION ALL SELECT 'citus_50', count(*) FROM readings_citus_50;
