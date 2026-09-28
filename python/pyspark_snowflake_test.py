"""
Day 6 — Minimal PySpark <-> Snowflake connectivity test.

Hand this to whoever owns Member 2 (Sedona/PySpark) so their job can
read raw_device_pings / raw_store_locations from Snowflake and, later,
write the spatial-join output back.

Requires: pip install pyspark snowflake-connector-python
          + the Snowflake Spark Connector + JDBC driver jars on the
          Spark classpath (see setup/SETUP_GUIDE.md).
"""
import os
from pyspark.sql import SparkSession

SF_OPTIONS = {
    "sfURL": os.environ["SNOWFLAKE_ACCOUNT_URL"],       # e.g. abc12345.snowflakecomputing.com
    "sfUser": os.environ["SNOWFLAKE_USER"],
    "sfPassword": os.environ["SNOWFLAKE_PASSWORD"],
    "sfDatabase": "GEOPULSE_DB",
    "sfSchema": "RAW",
    "sfWarehouse": "GEOPULSE_WH",
    "sfRole": "GEOPULSE_DEV",
}

SNOWFLAKE_SOURCE = "net.snowflake.spark.snowflake"


def main():
    spark = SparkSession.builder.appName("geopulse-snowflake-connectivity-test").getOrCreate()

    # Read: pull store locations into a Spark DataFrame
    stores_df = (
        spark.read.format(SNOWFLAKE_SOURCE)
        .options(**SF_OPTIONS)
        .option("dbtable", "RAW_STORE_LOCATIONS")
        .load()
    )
    print(f"Loaded {stores_df.count()} store rows from Snowflake")
    stores_df.show(5)

    # Write: prove round-trip works by writing a tiny test table back
    test_df = spark.createDataFrame([("ping_test_1", 12.97, 77.59)], ["device_id", "lat", "long"])
    (
        test_df.write.format(SNOWFLAKE_SOURCE)
        .options(**SF_OPTIONS)
        .option("dbtable", "CONNECTIVITY_TEST")
        .mode("overwrite")
        .save()
    )
    print("Write test succeeded — Spark can round-trip data with Snowflake.")

    spark.stop()


if __name__ == "__main__":
    main()
