"""Airflow orchestration for the Northwind Marketing Analytics project.

This DAG validates that raw Snowflake inputs are present, triggers the existing
dbt Cloud Production Build job, and validates that the final marts contain data.

Recommended setup:
- Airflow connection: snowflake_northwind
- Airflow connection: dbt_cloud_default
- dbt Cloud project: NORTHWIND ANALYTICS
- dbt Cloud environment: Production
- dbt Cloud job: Production Build

If Airflow owns the schedule, disable the schedule inside dbt Cloud to avoid
duplicate production runs.
"""

from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLCheckOperator
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator


DEFAULT_ARGS = {
    "owner": "analytics-engineering",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


with DAG(
    dag_id="northwind_marketing_pipeline",
    description="Validate Snowflake RAW data and trigger the dbt Cloud production build.",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 1, 1),
    schedule="0 7 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["snowflake", "dbt", "marketing"],
) as dag:

    check_raw_sources = SQLCheckOperator(
        task_id="check_raw_sources",
        conn_id="snowflake_northwind",
        sql="""
        select
            (select count(*) from NORTHWIND.RAW.CUSTOMERS) > 0
            and (select count(*) from NORTHWIND.RAW.ORDERS) > 0
            and (select count(*) from NORTHWIND.RAW.WEB_EVENTS) > 0
            and (select count(*) from NORTHWIND.RAW.GOOGLE_ADS_SPEND) > 0
            and (select count(*) from NORTHWIND.RAW.META_ADS_SPEND) > 0
        """,
    )

    run_dbt_production = DbtCloudRunJobOperator(
        task_id="run_dbt_production",
        dbt_cloud_conn_id="dbt_cloud_default",
        project_name="NORTHWIND ANALYTICS",
        environment_name="Production",
        job_name="Production Build",
        wait_for_termination=True,
        check_interval=30,
        timeout=3600,
        trigger_reason="Triggered by Airflow DAG northwind_marketing_pipeline",
    )

    check_final_marts = SQLCheckOperator(
        task_id="check_final_marts",
        conn_id="snowflake_northwind",
        sql="""
        select
            (select count(*) from NORTHWIND.PROD_MARTS.FCT_AD_SPEND) > 0
            and (select count(*) from NORTHWIND.PROD_MARTS.MART_CHANNEL_PERFORMANCE) > 0
            and (select count(*) from NORTHWIND.PROD_MARTS.MART_CUSTOMER_LTV) > 0
            and (select count(*) from NORTHWIND.PROD_MARTS.MART_FUNNEL) > 0
        """,
    )

    check_raw_sources >> run_dbt_production >> check_final_marts
