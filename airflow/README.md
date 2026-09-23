# Airflow orchestration

This folder adds a Python/Airflow orchestration layer around the existing Snowflake + dbt Cloud project.

## What the DAG does

```text
Check Snowflake RAW tables
          ↓
Trigger dbt Cloud "Production Build"
          ↓
Wait for dbt Cloud success
          ↓
Validate final PROD_MARTS tables
```

The dbt Cloud job remains responsible for:

- `dbt deps`
- source freshness
- `dbt build`
- tests and snapshots
- documentation generation

Airflow coordinates the broader workflow.

## Airflow connections

Create these connections in Airflow:

### `snowflake_northwind`

Point it to the same Snowflake environment used by dbt:

- Database: `NORTHWIND`
- Warehouse: `TRANSFORM_WH_XS`
- Role: `TRANSFORMER`
- Authentication: use your organization's approved secret/key management approach

### `dbt_cloud_default`

Use the dbt Cloud connection type. Store the dbt Cloud API token in the Airflow connection rather than in source code.

The DAG identifies the existing job by name:

- Project: `NORTHWIND ANALYTICS`
- Environment: `Production`
- Job: `Production Build`

## Scheduling

The example DAG is scheduled for `07:00 UTC`.

**Important:** choose one scheduler for production. If Airflow owns the schedule, disable the dbt Cloud schedule so the pipeline does not run twice.

## Alerting ownership

While dbt Cloud owns the production schedule, configure failed-run and freshness notifications in dbt Cloud. The setup and safe validation procedure are documented in [`../docs/alerting.md`](../docs/alerting.md).

If Airflow becomes the production scheduler later, move orchestration-level failure notifications to Airflow and disable the dbt Cloud schedule so the same pipeline is not triggered twice.

## Dependencies

Install the packages from `airflow/requirements.txt` into an existing Airflow environment.

The official Airflow dbt Cloud provider exposes `DbtCloudRunJobOperator`, which triggers and waits for a dbt Cloud job. The Snowflake provider is used for SQL validation tasks.
