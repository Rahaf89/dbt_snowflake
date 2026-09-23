# Marketing anomaly detection

The project detects unusual channel-level movements in:

- paid media spend
- attributed revenue
- conversion rate

## Models

```text
MON_MARKETING_DAILY_METRICS
        ↓
MON_MARKETING_ANOMALIES
```

The daily model combines `FCT_AD_SPEND`, `INT_ATTRIBUTED_REVENUE`, and `MART_FUNNEL` at one row per channel/day.

The anomaly model calculates a rolling mean and sample standard deviation from prior observations only, then converts the current value into a z-score.

## Configuration

```yaml
vars:
  anomaly_lookback_periods: 28
  anomaly_min_history_periods: 7
  anomaly_zscore_threshold: 3.0
```

A value is flagged only when:

1. enough prior observations exist,
2. historical standard deviation is greater than zero, and
3. the absolute z-score meets or exceeds the configured threshold.

## Build and validate

In dbt Cloud development:

```bash
dbt build --select mon_marketing_daily_metrics mon_marketing_anomalies
```

Then inspect detected anomalies:

```sql
select
    metric_date,
    channel,
    daily_spend,
    spend_zscore,
    attributed_revenue,
    revenue_zscore,
    conversion_rate,
    conversion_rate_zscore
from NORTHWIND.DBT_ANALYTICS_MONITORING.MON_MARKETING_ANOMALIES
where is_any_anomaly
order by metric_date desc, channel;
```

After merge and a successful Production Build, use:

```sql
select *
from NORTHWIND.PROD_MONITORING.MON_MARKETING_ANOMALIES
where is_any_anomaly
order by metric_date desc, channel;
```

## Warning-level dbt test

`tests/warn_on_marketing_anomalies.sql` returns anomalous rows with `severity='warn'`.

That means anomalies are visible in dbt run results without automatically blocking production deployment. This is intentional for the synthetic portfolio dataset. In a live system, the severity and notification routing can be tightened once the expected baseline behavior is understood.

## Interpretation

A z-score is a distance from the historical rolling mean measured in historical standard deviations. It identifies unusual movement; it does not prove that the value is wrong.

An anomaly should trigger investigation into things such as campaign changes, tracking issues, ingestion gaps, attribution changes, promotions, or genuine shifts in customer behavior.
