/* =====================================================================
   Day 2 — GEOGRAPHY-typed tables for raw device pings + store locations
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA RAW;

-- Raw device pings (one row per GPS ping, as produced by Member 2's
-- mock-data generator and landed here before Sedona/dbt processing)
CREATE TABLE IF NOT EXISTS raw_device_pings (
    device_id       STRING        NOT NULL,
    ping_geo        GEOGRAPHY     NOT NULL,   -- built from lat/long via ST_MAKEPOINT
    latitude         FLOAT        NOT NULL,
    longitude        FLOAT        NOT NULL,
    ping_ts          TIMESTAMP_NTZ NOT NULL,
    source_file       STRING,                  -- provenance: which load file this came from
    loaded_at        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Landing table for raw anonymized mobile device pings (DeviceID, Lat, Long, Timestamp)';

-- Raw store locations (point geometry — the coffee chain's stores)
CREATE TABLE IF NOT EXISTS raw_store_locations (
    store_id         STRING        NOT NULL,
    store_name        STRING,
    store_geo        GEOGRAPHY     NOT NULL,
    latitude          FLOAT        NOT NULL,
    longitude         FLOAT        NOT NULL,
    loaded_at         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Landing table for the 5,000 mock store point locations';

-- Helper: how a GEOGRAPHY point column gets populated from lat/long
-- (used by the bulk-load COPY step in Day 4, shown here for reference)
-- ping_geo = ST_MAKEPOINT(longitude, latitude)   -- note: (lon, lat) order!

SELECT 'raw_device_pings' AS table_name, COUNT(*) AS row_count FROM raw_device_pings
UNION ALL
SELECT 'raw_store_locations', COUNT(*) FROM raw_store_locations;
