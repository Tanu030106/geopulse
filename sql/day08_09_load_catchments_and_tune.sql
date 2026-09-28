/* =====================================================================
   Day 8 — Load generated catchment polygons as GEOGRAPHY; validate
           against store points
   Day 9 — Tune read/write performance for the spatial job
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA STAGING;

/* ---------------------------------------------------------------------
   Day 8: if you used the Python generator (WKT CSV), load it here.
   If you used the SQL ST_BUFFER alternative (Day 7 SQL), skip straight
   to the "official" table rename below.
   --------------------------------------------------------------------- */

CREATE STAGE IF NOT EXISTS catchment_stage
  FILE_FORMAT = RAW.CSV_STANDARD
  COMMENT = 'Landing stage for catchment polygon WKT CSVs';

-- PUT file://catchments.csv @catchment_stage AUTO_COMPRESS=TRUE;

CREATE TABLE IF NOT EXISTS store_catchment_polygons (
    store_id      STRING    NOT NULL,
    catchment_geo GEOGRAPHY NOT NULL,
    radius_m      FLOAT,
    loaded_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

COPY INTO store_catchment_polygons (store_id, catchment_geo, radius_m)
FROM (
    SELECT
        $1                     AS store_id,
        TO_GEOGRAPHY($2)       AS catchment_geo,   -- parses the WKT polygon string
        $3::FLOAT              AS radius_m
    FROM @catchment_stage
)
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_STANDARD)
ON_ERROR = 'CONTINUE';

-- Validate: every catchment must be a valid polygon and must actually
-- contain its own store point (sanity check the buffer math)
SELECT
    c.store_id,
    ST_ISVALID(c.catchment_geo)                         AS is_valid_polygon,
    ST_CONTAINS(c.catchment_geo, s.store_geo)            AS contains_own_store
FROM store_catchment_polygons c
JOIN RAW.raw_store_locations s USING (store_id)
WHERE NOT ST_ISVALID(c.catchment_geo)
   OR NOT ST_CONTAINS(c.catchment_geo, s.store_geo);
-- Empty result = every catchment polygon is valid and encloses its store. Good.

/* ---------------------------------------------------------------------
   Day 9 — Performance tuning for the spatial workload
   --------------------------------------------------------------------- */

-- 1. Clustering key: pings are usually queried/joined by geography and
--    time, so cluster on ping_ts (device_id alone has too high cardinality
--    to be a useful clustering key at billions of rows).
ALTER TABLE RAW.raw_device_pings CLUSTER BY (DATE(ping_ts));

-- 2. Check clustering health periodically as data grows
SELECT SYSTEM$CLUSTERING_INFORMATION('RAW.raw_device_pings', '(DATE(ping_ts))');

-- 3. Warehouse sizing guidance for the Sedona spatial join (Member 2):
--    - Dev/test on a few thousand rows: XSMALL is fine.
--    - Full 5-10M row spatial join: scale GEOPULSE_WH to MEDIUM or
--      LARGE for the duration of the job only, then scale back down
--      (or rely on AUTO_SUSPEND) to control credit spend.
ALTER WAREHOUSE GEOPULSE_WH SET WAREHOUSE_SIZE = 'MEDIUM';   -- before a big job
-- ALTER WAREHOUSE GEOPULSE_WH SET WAREHOUSE_SIZE = 'XSMALL'; -- afterwards

-- 4. Multi-cluster warehouse (optional) if multiple teammates query
--    concurrently during demo/review — avoids queueing:
-- ALTER WAREHOUSE GEOPULSE_WH SET
--     MIN_CLUSTER_COUNT = 1
--     MAX_CLUSTER_COUNT = 2
--     SCALING_POLICY = 'STANDARD';
