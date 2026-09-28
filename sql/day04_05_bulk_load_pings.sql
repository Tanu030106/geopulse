/* =====================================================================
   Day 4 — Bulk-load process (stage + COPY INTO) for incoming ping files
   Day 5 — Verification queries + schema/loading docs (see docs/)
   Pings arrive as CSV or Parquet from Member 2's mock-data generator
   (~5-10 million rows).
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA RAW;

-- 1. File formats
CREATE FILE FORMAT IF NOT EXISTS PARQUET_STANDARD
  TYPE = 'PARQUET';

-- 2. Stage for ping files (CSV during dev, Parquet once Member 2's
--    dataset is finalized — day 4/5 of their track)
CREATE STAGE IF NOT EXISTS ping_stage
  FILE_FORMAT = CSV_STANDARD
  COMMENT = 'Landing stage for device ping CSV/Parquet files';

-- Upload examples (run from SnowSQL CLI on your laptop):
--   PUT file://pings_2026-09-01.csv @ping_stage AUTO_COMPRESS=TRUE;
--   PUT file://pings_2026-09-01.parquet @ping_stage AUTO_COMPRESS=TRUE;

-- 3a. Bulk load — CSV variant
COPY INTO raw_device_pings (device_id, ping_geo, latitude, longitude, ping_ts, source_file)
FROM (
    SELECT
        $1                                  AS device_id,
        ST_MAKEPOINT($3::FLOAT, $2::FLOAT)  AS ping_geo,     -- (lon, lat)
        $2::FLOAT                           AS latitude,
        $3::FLOAT                           AS longitude,
        $4::TIMESTAMP_NTZ                   AS ping_ts,
        METADATA$FILENAME                   AS source_file
    FROM @ping_stage
)
PATTERN = '.*\.csv'
FILE_FORMAT = (FORMAT_NAME = CSV_STANDARD)
ON_ERROR = 'CONTINUE';   -- log bad rows instead of aborting a multi-million-row load

-- 3b. Bulk load — Parquet variant (columns: device_id, lat, long, ts)
COPY INTO raw_device_pings (device_id, ping_geo, latitude, longitude, ping_ts, source_file)
FROM (
    SELECT
        $1:device_id::STRING                        AS device_id,
        ST_MAKEPOINT($1:long::FLOAT, $1:lat::FLOAT)  AS ping_geo,
        $1:lat::FLOAT                                AS latitude,
        $1:long::FLOAT                                AS longitude,
        $1:timestamp::TIMESTAMP_NTZ                  AS ping_ts,
        METADATA$FILENAME                             AS source_file
    FROM @ping_stage
)
PATTERN = '.*\.parquet'
FILE_FORMAT = (FORMAT_NAME = PARQUET_STANDARD)
ON_ERROR = 'CONTINUE';

-- 4. Check which files loaded, and how many rows/errors each produced
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'RAW_DEVICE_PINGS',
    START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
));

/* ---------------------------------------------------------------------
   Day 5 — Verification / smoke-test queries
   --------------------------------------------------------------------- */

-- Row count sanity check (expect millions once full dataset lands)
SELECT COUNT(*) AS total_pings FROM raw_device_pings;

-- Distinct devices and date range covered
SELECT
    COUNT(DISTINCT device_id) AS distinct_devices,
    MIN(ping_ts)              AS earliest_ping,
    MAX(ping_ts)              AS latest_ping
FROM raw_device_pings;

-- Geometry sanity: any null or invalid points?
SELECT COUNT_IF(ping_geo IS NULL) AS null_geo,
       COUNT_IF(NOT ST_ISVALID(ping_geo)) AS invalid_geo
FROM raw_device_pings;

-- Rows per hour of day (should roughly show morning/evening commute peaks
-- once Member 2's realistic traffic patterns are loaded)
SELECT DATE_PART('hour', ping_ts) AS hour_of_day, COUNT(*) AS ping_count
FROM raw_device_pings
GROUP BY 1
ORDER BY 1;
