# Member 3 – Part A: Distributed Warehouse (Spark + Citus)

Smart Meter Energy Consumption Analytics (London LCL dataset). This document covers Tasks 1–8 of Member 3: Spark processing, a Citus distributed warehouse, distribution-key evaluation, and a performance comparison against centralized PostgreSQL.

## 1. Environment

| Component | Details |
|---|---|
| Machine | Single Windows laptop (all components share the same CPU and RAM) |
| Spark | PySpark 4.3.0, local mode, Java 17 (Temurin), driver memory 4 GB |
| Windows Hadoop libs | `winutils.exe` and `hadoop.dll` (Hadoop 3.3.6) under `C:\hadoop\bin` |
| Citus | `citusdata/citus` in Docker: 1 coordinator + 2 workers |
| Shard layout | 32 shards for the main distributed table: 16 on `citus_worker1`, 16 on `citus_worker2` |

## 2. Data and Spark processing (Tasks 1–2)

Input is the cleaned Parquet data from Member 1 (a sample of the files was used on this laptop). The sample holds **4,928,948 rows**, all with the ToU tariff.

Columns used: `lclid` (household), `tariff`, `reading_ts`, `reading_date`, `year`, `month`, `day`, `hour`, `day_of_week`, `day_type`, `half_hour`, `consumption_kwh`.

Processing steps in Spark:

1. Selected the clean columns and renamed them to database-friendly names. The raw string column `KWH/hh (per half hour)` was dropped because its name contains spaces and symbols, and `consumption_kwh` already holds the numeric value.
2. Dropped rows with a null `lclid`, `reading_ts` or `consumption_kwh`, and removed duplicates on (`lclid`, `reading_ts`).
3. Built three aggregates: daily usage per household, average usage by hour and tariff, and weekday vs weekend averages.
4. Exported the cleaned data and aggregates as CSV for loading into PostgreSQL/Citus.

Observations from the sample: usage is lowest around 03:00 (about 0.096 kWh per half hour) and highest around 08:00–09:00 (about 0.22 kWh). Weekend average (0.211) is slightly higher than weekday (0.204).

## 3. Citus setup and distributed tables (Tasks 3–4)

- Cluster: `citus_master` (coordinator) plus `citus_worker1` and `citus_worker2`, started with Docker Compose.
- `readings_pg`: regular PostgreSQL table (centralized baseline), loaded with `COPY` from the Spark CSV export.
- `readings_citus`: distributed with `create_distributed_table('readings_citus', 'lclid')`.
- Row counts matched across Spark, PostgreSQL and Citus: 4,928,948.

## 4. Distribution key evaluation (Task 5)

| Key | Reasoning |
|---|---|
| `lclid` (chosen) | Many distinct household values spread rows across shards. Queries that group or filter by household are handled within a shard, and per-household data stays together. |
| `reading_date` (tested) | Also distributes data, but the main per-household analysis then touches every shard. Time-based keys can also concentrate recent-date queries on fewer shards. |

Both keys were loaded and queried (`readings_citus` and `readings_citus_date`). In the benchmark runs the timings were noisy and did not clearly separate the two keys, so the choice of `lclid` rests mainly on the design reasoning above.

## 5. Benchmark method (Tasks 6–7)

- Tables: `readings_pg_20`, `readings_pg_50`, `readings_pg` and the matching Citus tables `readings_citus_20`, `readings_citus_50`, `readings_citus` (distributed on `lclid`).
- Sizes: 987,122 rows (about 20%), 2,464,181 rows (about 50%), 4,928,948 rows (100%). The subsets were taken with `random() < 0.2` and `random() < 0.5`.
- Queries:
  - Q1: `count(*)` and `avg(consumption_kwh)` over the table
  - Q2: average consumption by hour
  - Q3: top 10 households by total consumption
  - Q4: top 10 dates by total consumption
- Timing: psql `\timing`, 3 runs of the full script, **best (minimum) time of the 3 runs** reported.

## 6. Results (milliseconds, best of 3 runs)

| Rows | Query | PostgreSQL | Citus (`lclid`) | Result |
|---|---|---:|---:|---|
| 987,122 | Q1 count + avg | 513 | 694 | PostgreSQL faster |
| 987,122 | Q2 hourly avg | 259 | 244 | Comparable |
| 987,122 | Q3 top households | 193 | 200 | Comparable |
| 987,122 | Q4 top dates | 195 | 208 | Comparable |
| 2,464,181 | Q1 count + avg | 2,530 | 2,311 | Comparable |
| 2,464,181 | Q2 hourly avg | 379 | 706 | PostgreSQL faster |
| 2,464,181 | Q3 top households | 416 | 383 | Comparable |
| 2,464,181 | Q4 top dates | 382 | 345 | Comparable |
| 4,928,948 | Q1 count + avg | 4,278 | 5,903 | PostgreSQL faster |
| 4,928,948 | Q2 hourly avg | 1,452 | 1,046 | Citus faster |
| 4,928,948 | Q3 top households | 848 | 1,531 | PostgreSQL faster |
| 4,928,948 | Q4 top dates | 754 | 1,220 | PostgreSQL faster |

"Comparable" means the two times are within about 10% of each other.

## 7. Observations

- There is **no consistent winner**. Of 12 comparisons, 5 favour PostgreSQL clearly, 1 favours Citus clearly, and 6 are comparable.
- Query time grows with table size for both systems. Within up to about 5 million rows, Citus does not show a clear advantage over a single PostgreSQL instance.
- Run-to-run variance was large. For example, the full-size Citus Q3 took between 1.5 s and 32 s across the three runs, and the full-size PostgreSQL Q1 between 4.3 s and 14.3 s. Individual runs should therefore not be over-interpreted.

## 8. Limitations and interpretation

- The coordinator, both workers, Spark and Jupyter all ran on one laptop and competed for the same CPU, memory and disk. Citus normally gains from workers that have their own hardware. Here it pays the cost of distribution (planning, coordinator–worker communication) without gaining extra compute.
- The dataset is about 5 million rows. Citus is designed for much larger tables, where a single PostgreSQL node becomes the limit.
- Only the ToU tariff is present in the sample used, and only four query types were tested.
- Timings were taken on a busy laptop, which explains the spikes in the raw runs.

## 9. Conclusion

The Citus cluster works correctly: data is split evenly across two workers (16 shards each) and returns the same row counts and results as PostgreSQL. In this single-machine setup, performance is broadly comparable to centralized PostgreSQL, with PostgreSQL ahead on several queries. A real speed-up from distribution would be expected with workers on separate machines and a much larger dataset. Distribution on `lclid` is the recommended key for this workload.

## 10. Reproduce

```
cd C:\data\citus
docker compose up -d
docker exec citus_master psql -U postgres -f /data/setup.sql
docker exec citus_master psql -U postgres -f /data/setup_sizes.sql
1..3 | ForEach-Object { docker exec citus_master psql -U postgres -f /data/bench_sizes.sql | Select-String "=====|Time:" }
```
