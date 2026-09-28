/* =====================================================================
   Day 7 (alternative) — Generate 500m catchment polygons purely in SQL
   using ST_BUFFER, instead of the Python script. Either approach is
   fine; pick one so the team doesn't maintain two versions.
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA STAGING;

CREATE TABLE IF NOT EXISTS store_catchment_polygons_preview AS
SELECT
    store_id,
    store_geo,
    -- ST_BUFFER distance is in the units of the geography (meters for GEOGRAPHY)
    ST_BUFFER(store_geo, 500) AS catchment_geo,
    500 AS radius_m
FROM RAW.raw_store_locations;

-- Quick visual/row sanity check
SELECT store_id, ST_ASGEOJSON(catchment_geo) AS catchment_geojson
FROM store_catchment_polygons_preview
LIMIT 5;
