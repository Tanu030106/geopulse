/* =====================================================================
   Day 1 — Snowflake account / warehouse / database / schema setup
   Owner: Member 1 (Data Lakehouse)
   ===================================================================== */

-- Run as ACCOUNTADMIN (or ask your Snowflake trial admin to run this once)

-- 1. Dedicated warehouse for GeoPulse
CREATE WAREHOUSE IF NOT EXISTS GEOPULSE_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60          -- suspend after 60s idle (keeps free-trial credits alive)
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Warehouse for GeoPulse hyper-local retail mobility analytics';

-- 2. Database
CREATE DATABASE IF NOT EXISTS GEOPULSE_DB
  COMMENT = 'Raw + modeled data for the GeoPulse project';

-- 3. Schemas — one per pipeline stage (naming convention below)
USE DATABASE GEOPULSE_DB;

CREATE SCHEMA IF NOT EXISTS RAW        COMMENT = 'Landing zone: unmodified ping/store data as loaded';
CREATE SCHEMA IF NOT EXISTS STAGING    COMMENT = 'Cleaned/typed data, written by Sedona + dbt staging models';
CREATE SCHEMA IF NOT EXISTS ANALYTICS  COMMENT = 'Final marts: footfall, cannibalization (owned by Member 3 / dbt)';

-- 4. Role + grants (keep it simple for a 4-person student project:
--    one shared role, everyone logs in with their own user)
CREATE ROLE IF NOT EXISTS GEOPULSE_DEV;

GRANT USAGE ON WAREHOUSE GEOPULSE_WH TO ROLE GEOPULSE_DEV;
GRANT ALL ON DATABASE GEOPULSE_DB TO ROLE GEOPULSE_DEV;
GRANT ALL ON ALL SCHEMAS IN DATABASE GEOPULSE_DB TO ROLE GEOPULSE_DEV;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE GEOPULSE_DB TO ROLE GEOPULSE_DEV;

-- Assign the role to your user (repeat for each teammate)
-- GRANT ROLE GEOPULSE_DEV TO USER <your_username>;

-- 5. Sanity check
USE WAREHOUSE GEOPULSE_WH;
USE SCHEMA GEOPULSE_DB.RAW;
SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_ROLE();

/* -----------------------------------------------------------------------
   NAMING CONVENTIONS (document for the team — see docs/schema_design.md)
   - Databases: GEOPULSE_DB
   - Schemas:   RAW / STAGING / ANALYTICS
   - Tables:    snake_case, singular domain noun + purpose
                e.g. raw_device_pings, store_catchment_polygons
   - Warehouse: GEOPULSE_WH, XSMALL, auto-suspend 60s (cost control)
   ----------------------------------------------------------------------- */
