# GeoPulse — Member 1: Data Lakehouse (Snowflake)

Owns: raw data storage, GEOGRAPHY tables, catchment polygons, visit logs,
and Airflow ingestion — the full 20-day work plan.

## Folder structure
```
member1-snowflake-lakehouse/
├── sql/          -- one file per day (or day range), run in Snowsight in order
├── python/        -- mock data + catchment polygon generators, PySpark connectivity test
├── airflow/dags/  -- the daily ingestion DAG (Days 16-19)
├── docs/          -- schema design, ERD, final documentation (Days 10, 15, 20)
└── setup/         -- SETUP_GUIDE.md: Snowflake account, laptop tools, git workflow
```

## Quick start
1. Read `setup/SETUP_GUIDE.md` first — it walks through the free Snowflake
   trial, local Python/Airflow setup, and pushing this to git.
2. Run the `sql/dayXX_*.sql` files in Snowsight in numeric order.
3. Run the `python/` scripts locally to generate mock data before loading it.
4. Deploy `airflow/dags/geopulse_snowflake_dag.py` once you want the daily
   pipeline running automatically.

## Day-by-day map
| Days | Deliverable |
|---|---|
| 1-2 | `sql/day01_setup_account.sql`, `sql/day02_geography_tables.sql` |
| 3 | `python/generate_mock_stores.py` + `sql/day03_load_and_validate_stores.sql` |
| 4-5 | `sql/day04_05_bulk_load_pings.sql` |
| 6 | `sql/day06_pyspark_connector.sql` + `python/pyspark_snowflake_test.py` |
| 7-9 | `python/generate_catchment_polygons.py` (or `sql/day07_catchment_sql_alternative.sql`) + `sql/day08_09_load_catchments_and_tune.sql` |
| 10 | `docs/schema_design.md` |
| 11-14 | `sql/day11_15_device_visit_log.sql` |
| 15 | `docs/visit_tracking_erd.md` |
| 16-19 | `airflow/dags/geopulse_snowflake_dag.py` |
| 20 | `docs/final_documentation.md` |
