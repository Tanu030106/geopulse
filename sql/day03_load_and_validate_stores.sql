/* =====================================================================
   Day 3 — Load 5,000 mock store points into Snowflake, verify geometry
   Pre-req: run python/generate_mock_stores.py -> stores.csv
            and upload it to the STORE_STAGE (see Day 4 for stage/PUT).
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA RAW;

-- 1. File format for the CSV Member 2/1 generated
CREATE FILE FORMAT IF NOT EXISTS CSV_STANDARD
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL');

-- 2. Internal stage to receive the CSV
--    Upload with SnowSQL CLI:  PUT file://stores.csv @store_stage AUTO_COMPRESS=TRUE;
CREATE STAGE IF NOT EXISTS store_stage
  FILE_FORMAT = CSV_STANDARD
  COMMENT = 'Landing stage for mock store location CSVs';

-- 3. Load into RAW.raw_store_locations, converting lat/long into GEOGRAPHY
COPY INTO raw_store_locations (store_id, store_name, store_geo, latitude, longitude)
FROM (
    SELECT
        $1                                    AS store_id,
        $2                                    AS store_name,
        ST_MAKEPOINT($4::FLOAT, $3::FLOAT)    AS store_geo,   -- (lon, lat)
        $3::FLOAT                             AS latitude,
        $4::FLOAT                             AS longitude
    FROM @store_stage
)
FILE_FORMAT = (FORMAT_NAME = CSV_STANDARD)
ON_ERROR = 'ABORT_STATEMENT';

-- 4. Verify row count matches the generator (expect 5,000)
SELECT COUNT(*) AS store_count FROM raw_store_locations;

-- 5. Validate geometry: every store_geo must be a valid, non-null POINT
SELECT
    COUNT(*)                                            AS total_rows,
    COUNT_IF(store_geo IS NULL)                         AS null_geo,
    COUNT_IF(ST_ISVALID(store_geo) = FALSE)             AS invalid_geo,
    COUNT_IF(ST_ASGEOJSON(store_geo):type::STRING != 'Point') AS wrong_type
FROM raw_store_locations;

-- Any row with invalid_geo > 0 or wrong_type > 0 needs investigation —
-- typically a swapped lat/long or an out-of-range coordinate.
SELECT store_id, latitude, longitude, store_geo
FROM raw_store_locations
WHERE NOT ST_ISVALID(store_geo)
   OR latitude NOT BETWEEN -90 AND 90
   OR longitude NOT BETWEEN -180 AND 180;
