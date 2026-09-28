"""
Day 16 — Airflow DAG skeleton
Day 17 — Daily ping ingestion task (extract -> stage -> load)
Day 18 — Retries, timeouts, failure alerts
Day 19 — This is what gets dry-run end-to-end against the full pipeline

Requires: pip install apache-airflow apache-airflow-providers-snowflake
Place this file in your Airflow `dags/` folder (see setup/SETUP_GUIDE.md
for local Airflow setup).
"""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
from airflow.utils.email import send_email

SNOWFLAKE_CONN_ID = "geopulse_snowflake"   # configured in Airflow Connections UI

default_args = {
    "owner": "member1-data-lakehouse",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(minutes=30),
    "email_on_failure": True,
    "email": ["your-team-alerts@example.com"],  # Day 18: failure alert recipients
}


def alert_on_failure(context):
    """Day 18 — custom failure alert with task/DAG context (Slack-friendly)."""
    task_instance = context["task_instance"]
    msg = (
        f"GeoPulse pipeline FAILED\n"
        f"DAG: {context['dag'].dag_id}\n"
        f"Task: {task_instance.task_id}\n"
        f"Execution date: {context['execution_date']}\n"
        f"Log: {task_instance.log_url}"
    )
    # Swap this for a Slack webhook call if your team sets one up;
    # plain email is the zero-setup option for a student project.
    send_email(to=default_args["email"], subject="[GeoPulse] Airflow task failed", html_content=msg)


def extract_and_stage_pings(**context):
    """
    Day 17 step 1 (extract -> stage): pulls the day's ping file from
    wherever Member 2's generator drops it, and PUTs it to the
    Snowflake internal stage. Swap the source path for S3/GCS as needed.
    """
    hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
    ds = context["ds"]  # YYYY-MM-DD
    local_file = f"/data/geopulse/pings_{ds}.csv"
    put_sql = f"PUT file://{local_file} @GEOPULSE_DB.RAW.ping_stage AUTO_COMPRESS=TRUE OVERWRITE=TRUE"
    hook.run(put_sql)
    print(f"Staged {local_file} to @ping_stage")


with DAG(
    dag_id="geopulse_snowflake_daily_load",
    description="Daily ingestion of device pings into Snowflake RAW layer",
    default_args=default_args,
    schedule_interval="@daily",
    start_date=datetime(2026, 9, 1),
    catchup=False,
    on_failure_callback=alert_on_failure,
    tags=["geopulse", "member1", "snowflake"],
) as dag:

    # Day 17: extract -> stage
    extract_stage = PythonOperator(
        task_id="extract_and_stage_pings",
        python_callable=extract_and_stage_pings,
    )

    # Day 17: stage -> load (COPY INTO)
    load_pings = SnowflakeOperator(
        task_id="copy_into_raw_device_pings",
        snowflake_conn_id=SNOWFLAKE_CONN_ID,
        sql="""
            COPY INTO GEOPULSE_DB.RAW.raw_device_pings
                (device_id, ping_geo, latitude, longitude, ping_ts, source_file)
            FROM (
                SELECT
                    $1,
                    ST_MAKEPOINT($3::FLOAT, $2::FLOAT),
                    $2::FLOAT,
                    $3::FLOAT,
                    $4::TIMESTAMP_NTZ,
                    METADATA$FILENAME
                FROM @GEOPULSE_DB.RAW.ping_stage
            )
            FILE_FORMAT = (FORMAT_NAME = GEOPULSE_DB.RAW.CSV_STANDARD)
            ON_ERROR = 'CONTINUE';
        """,
    )

    # Day 18: post-load row count check -> fails the task (triggering
    # retries/alerts above) if nothing loaded
    verify_load = SnowflakeOperator(
        task_id="verify_load_row_count",
        snowflake_conn_id=SNOWFLAKE_CONN_ID,
        sql="""
            SELECT CASE WHEN COUNT(*) = 0 THEN 1/0 ELSE 1 END
            FROM GEOPULSE_DB.RAW.raw_device_pings
            WHERE DATE(loaded_at) = CURRENT_DATE();
        """,
    )

    extract_stage >> load_pings >> verify_load
