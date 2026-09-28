/* =====================================================================
   Day 11 — Design device_visit_log schema
   Day 12 — Create table + populate from Sedona job output
   Day 13 — Optimize clustering keys for multi-store lookups
   Day 14 — Validate visit-log accuracy against known mock traffic
   Day 15 — (docs in docs/visit_tracking_erd.md)
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA STAGING;

/* ---------------------------------------------------------------------
   Day 11: Schema design
   Grain: one row per (device, store, visit event) — a "visit" is a
   contiguous block of pings for a device inside one store's catchment.
   This is what Member 2's Sedona job (ST_Intersects + nearest-store
   tagging) outputs, and what Member 3's dbt footfall models consume.
   --------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS device_visit_log (
    visit_id        STRING        NOT NULL,   -- surrogate key, e.g. HASH(device_id, store_id, visit_start)
    device_id       STRING        NOT NULL,
    store_id        STRING        NOT NULL,
    visit_date       DATE          NOT NULL,   -- partition-friendly column, derived from visit_start
    visit_start      TIMESTAMP_NTZ NOT NULL,
    visit_end        TIMESTAMP_NTZ,
    ping_count       NUMBER,                   -- how many pings made up this visit
    is_multi_store   BOOLEAN,                  -- flag set when the device's catchment overlapped 2+ stores
    source_job_run   STRING,                   -- Sedona/Airflow run id, for lineage/debugging
    loaded_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Device x store x date visit events, populated from the Sedona spatial-join output (Member 2)';

/* ---------------------------------------------------------------------
   Day 12: Populate from Sedona output.
   Member 2's job lands its output either (a) directly into Snowflake
   via the Spark connector, or (b) as Parquet on a stage. Below covers
   the stage/COPY path; if (a), Member 2 writes directly to this table
   and this step is just the initial table creation above.
   --------------------------------------------------------------------- */
CREATE STAGE IF NOT EXISTS sedona_output_stage
  FILE_FORMAT = RAW.PARQUET_STANDARD
  COMMENT = 'Landing stage for Sedona spatial-join output (device-to-store visit events)';

COPY INTO device_visit_log
    (visit_id, device_id, store_id, visit_date, visit_start, visit_end, ping_count, is_multi_store, source_job_run)
FROM (
    SELECT
        $1:visit_id::STRING,
        $1:device_id::STRING,
        $1:store_id::STRING,
        $1:visit_start::TIMESTAMP_NTZ::DATE,
        $1:visit_start::TIMESTAMP_NTZ,
        $1:visit_end::TIMESTAMP_NTZ,
        $1:ping_count::NUMBER,
        $1:is_multi_store::BOOLEAN,
        $1:job_run_id::STRING
    FROM @sedona_output_stage
)
FILE_FORMAT = (FORMAT_NAME = RAW.PARQUET_STANDARD)
ON_ERROR = 'CONTINUE';

/* ---------------------------------------------------------------------
   Day 13: Clustering for fast multi-store lookups.
   Common query patterns: "all visits for store X in date range",
   "all stores visited by device Y" -> cluster on (store_id, visit_date).
   --------------------------------------------------------------------- */
ALTER TABLE device_visit_log CLUSTER BY (store_id, visit_date);

SELECT SYSTEM$CLUSTERING_INFORMATION('device_visit_log', '(store_id, visit_date)');

/* ---------------------------------------------------------------------
   Day 14: Validate accuracy against known mock traffic patterns.
   Member 2's generator deliberately encodes morning/evening commute
   peaks — visit counts should reflect that shape.
   --------------------------------------------------------------------- */

-- 1. Visits per hour should peak in morning (7-9am) and evening (5-7pm)
SELECT DATE_PART('hour', visit_start) AS hour_of_day, COUNT(*) AS visit_count
FROM device_visit_log
GROUP BY 1
ORDER BY 1;

-- 2. No orphaned visits: every store_id must exist in raw_store_locations
SELECT v.store_id, COUNT(*) AS orphaned_visits
FROM device_visit_log v
LEFT JOIN RAW.raw_store_locations s ON v.store_id = s.store_id
WHERE s.store_id IS NULL
GROUP BY 1;
-- Expect zero rows.

-- 3. No visit_end before visit_start (data integrity)
SELECT COUNT(*) AS bad_time_ranges
FROM device_visit_log
WHERE visit_end IS NOT NULL AND visit_end < visit_start;
-- Expect 0.

-- 4. Spot-check: does a device tagged is_multi_store actually have
--    overlapping visits at the same time across 2+ stores?
SELECT device_id, visit_start, COUNT(DISTINCT store_id) AS concurrent_stores
FROM device_visit_log
WHERE is_multi_store = TRUE
GROUP BY device_id, visit_start
HAVING COUNT(DISTINCT store_id) < 2;
-- Any rows here = mislabeled is_multi_store flags; flag back to Member 2 for the Sedona join fix.
