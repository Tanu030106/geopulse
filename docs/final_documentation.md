# GeoPulse — Member 1 Final Documentation (Day 20)
## Snowflake Schema Design & Airflow Orchestration Architecture

## 1. What this track built
A Snowflake-based lakehouse layer for GeoPulse that:
- Ingests raw GPS device pings and store locations as `GEOGRAPHY` types (Days 1-5)
- Provides a PySpark/Sedona connectivity path for the spatial-join track (Day 6)
- Generates and validates 500m store catchment polygons (Days 7-9)
- Stores the resolved device-to-store visit events that feed dbt's footfall
  and cannibalization models (Days 11-15)
- Orchestrates daily ingestion end-to-end in Airflow with retries and
  failure alerting (Days 16-19)

## 2. Architecture diagram (text form)

```
[Member 2: mock ping generator] --CSV/Parquet--> [Airflow: extract_and_stage_pings]
                                                          │
                                                          ▼
                                          [Snowflake internal stage: ping_stage]
                                                          │  COPY INTO
                                                          ▼
                                         RAW.raw_device_pings (GEOGRAPHY)
                                                          │
                                    ┌─────────────────────┘
                                    ▼
                    [Member 2: Sedona/PySpark ST_Intersects join
                     against STAGING.store_catchment_polygons]
                                    │
                                    ▼
                    STAGING.device_visit_log  ───────►  [Member 3: dbt models]
                                                              │
                                                              ▼
                                                    ANALYTICS marts (footfall,
                                                    cannibalization) ─► [Member 4: Kepler.gl dashboard]
```

## 3. Schema design summary
See `docs/schema_design.md` for the full table reference. Three schemas
(`RAW`, `STAGING`, `ANALYTICS`) separate landing, spatial-processing, and
final-mart concerns, matching the four-owner pipeline split.

## 4. Airflow orchestration
- DAG: `geopulse_snowflake_daily_load` (`airflow/dags/geopulse_snowflake_dag.py`)
- Schedule: daily
- Tasks: extract & stage → COPY INTO → row-count verification
- Resilience: 3 retries with 5-minute backoff, 30-minute task timeout,
  email alert on failure with DAG/task/log context (Day 18)
- Dry-run process (Day 19): trigger the DAG manually against a small
  test file first (`airflow dags test geopulse_snowflake_daily_load
  2026-09-01`), confirm `verify_load_row_count` passes, then re-enable
  the daily schedule.

## 5. Known limitations / handoff notes for the team
- Catchment polygons are approximated as 32-sided regular polygons
  around each store point (good enough for city-scale, ~500m radius —
  the curvature error is negligible at this distance).
- `device_visit_log` assumes Member 2's Sedona job writes one row per
  continuous visit, not per raw ping — if that output shape changes,
  the `COPY INTO` in Day 12 needs its column mapping updated.
- Warehouse is sized XSMALL by default for cost control; scale to
  MEDIUM/LARGE only for the full multi-million-row spatial join, per
  Day 9 notes.
