from pathlib import Path


REQUIRED_PATHS = [
    "README.md",
    "dbt_project.yml",
    "packages.yml",
    "snowflake/01_setup.sql",
    "snowflake/02_raw_tables.sql",
    "snowflake/03_key_pair_template.sql",
    "ingestion/generate_data.py",
    "airflow/dags/northwind_marketing_pipeline.py",
    "models/staging/_sources.yml",
    "models/staging/stg_customers.sql",
    "models/staging/stg_orders.sql",
    "models/staging/stg_web_events.sql",
    "models/staging/stg_ad_spend.sql",
    "models/intermediate/int_customer_touchpoints.sql",
    "models/intermediate/int_attributed_revenue.sql",
    "models/marts/fct_ad_spend.sql",
    "models/marts/mart_channel_performance.sql",
    "models/marts/mart_customer_ltv.sql",
    "models/marts/mart_funnel.sql",
    "models/monitoring/mon_marketing_daily_metrics.sql",
    "models/monitoring/mon_marketing_anomalies.sql",
    "tests/warn_on_marketing_anomalies.sql",
    "docs/anomaly_detection.md",
    "docs/semantic_layer.md",
    "snapshots/scd_customers.sql",
    "tests/assert_spend_reconciles_to_source.sql",
]


def main() -> None:
    missing = [path for path in REQUIRED_PATHS if not Path(path).exists()]

    if missing:
        print("Missing required project files:")
        for path in missing:
            print(f" - {path}")
        raise SystemExit(1)

    print(f"Repository structure check passed ({len(REQUIRED_PATHS)} required files).")


if __name__ == "__main__":
    main()
