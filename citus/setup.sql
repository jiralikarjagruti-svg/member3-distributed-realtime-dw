CREATE TABLE readings_pg (
  lclid text, tariff text, reading_ts timestamp, reading_date date,
  year int, month int, day int, hour int,
  day_of_week text, day_type text, half_hour int,
  consumption_kwh double precision
);
COPY readings_pg FROM '/data/clean.csv' WITH (FORMAT csv, HEADER true);

CREATE TABLE readings_citus (LIKE readings_pg);
SELECT create_distributed_table('readings_citus', 'lclid');
INSERT INTO readings_citus SELECT * FROM readings_pg;
