/* =====================================================================
   Day 6 — External stage / connector so Member 2's PySpark+Sedona job
   can read from and write to Snowflake.
   ===================================================================== */
USE DATABASE GEOPULSE_DB;
USE SCHEMA RAW;

-- Option A (simplest for a student project): PySpark uses the
-- Snowflake Spark Connector (net.snowflake.spark.snowflake) and talks
-- to Snowflake directly via JDBC — no external stage needed. This is
-- the recommended path; the SQL below is only needed if you instead
-- want Sedona to write Parquet to cloud storage first.

-- Option B: external stage on cloud storage (S3/Azure Blob/GCS) that
-- both Snowflake and PySpark can read/write, useful if the team wants
-- Sedona's output landed as files before loading into Snowflake.
-- Replace the URL/credentials placeholders with your team's bucket.

-- CREATE STORAGE INTEGRATION geopulse_s3_int
--   TYPE = EXTERNAL_STAGE
--   STORAGE_PROVIDER = 'S3'
--   ENABLED = TRUE
--   STORAGE_AWS_ROLE_ARN = '<arn>'
--   STORAGE_ALLOWED_LOCATIONS = ('s3://geopulse-bucket/sedona-output/');

-- CREATE STAGE sedona_output_stage
--   URL = 's3://geopulse-bucket/sedona-output/'
--   STORAGE_INTEGRATION = geopulse_s3_int
--   FILE_FORMAT = PARQUET_STANDARD
--   COMMENT = 'Where Sedona/PySpark writes spatial-join output for Snowflake to ingest';

/* ---------------------------------------------------------------------
   PySpark side (give this snippet to Member 2 — pyspark_snowflake_test.py
   in python/ folder is a runnable version of this)
   --------------------------------------------------------------------- */
