# Production alerting

This project uses **dbt Cloud as the current production scheduler**, so production-run alerts are configured in dbt Cloud rather than in GitHub Actions.

## What should alert

The production job should notify on:

- failed dbt production runs
- source freshness failures
- cancelled production runs (optional but recommended)

Because the production job runs an explicit `dbt source freshness` step before `dbt build`, an `error_after` freshness breach causes the job to fail and therefore uses the same failure notification path as a model/test failure.

Current freshness rule:

```yaml
orders:
  loaded_at_field: order_timestamp
  freshness:
    warn_after:
      count: 400
      period: day
    error_after:
      count: 800
      period: day
```

> These wide thresholds are intentional for the static synthetic portfolio dataset. In a live daily-ingestion system they should be tightened to realistic SLAs.

## Production job order

Keep the dbt Cloud Production Build ordered like this:

```text
dbt deps
    ↓
dbt source freshness
    ↓
dbt build
    ↓
generate dbt documentation
```

The freshness command must remain an explicit job step so a stale source can fail the job before downstream transformations continue.

## Configure dbt Cloud notifications

Configure a notification for the existing **Production Build** job using either:

- the dbt Cloud user's email
- an external email address
- a Slack channel, if Slack is connected

Enable at least **job failure** notifications. Also enable **job cancellation** if you want cancelled runs surfaced.

No notification tokens, webhook URLs, email credentials, or Slack secrets belong in this repository.

## Safe notification test

The repository includes a dbt macro:

```text
macros/simulate_alert_failure.sql
```

It is deliberately guarded so it does nothing unless an explicit variable is supplied.

Create a temporary dbt Cloud job (for example `Alert Test`) and run:

```bash
dbt run-operation simulate_alert_failure --vars '{allow_alert_test: true}'
```

The command intentionally fails without modifying Snowflake data. Use it only in the temporary alert-test job, not in the Production Build.

Expected result:

```text
temporary Alert Test job
        ↓
intentional dbt failure
        ↓
dbt Cloud marks run as failed
        ↓
configured email / Slack notification arrives
```

After the alert arrives, delete or disable the temporary test job.

## Validate production-run alerts

1. Confirm the Production Build notification recipient is configured.
2. Confirm `dbt source freshness` is an explicit step before `dbt build`.
3. Run the safe temporary `Alert Test` job.
4. Confirm the run is marked failed.
5. Confirm the notification arrives and links back to the failed run.
6. Remove the temporary test job.

## Validate freshness behavior

For normal production runs, execute:

```bash
dbt source freshness
```

A source that exceeds `warn_after` produces a warning; a source that exceeds `error_after` should produce an error/failing freshness result. The Production Build's failure notification then covers the freshness incident.

Do **not** lower the production freshness threshold just to force an alert on the main production job. Use the safe temporary alert test above to validate delivery.

## If Airflow becomes the scheduler later

If the project later switches from the dbt Cloud schedule to the included Airflow DAG, keep only one production scheduler. Airflow can then own failure callbacks/notifications while the dbt Cloud job remains the transformation execution unit.
