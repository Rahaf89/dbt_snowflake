# dbt Semantic Layer

The project uses the dbt Semantic Layer / MetricFlow to keep important marketing definitions in one governed location rather than reimplementing them separately in dashboards.

The configuration follows dbt's latest YAML specification, where semantic annotations are embedded directly in model YAML and simple metrics are defined alongside their model. Advanced metrics such as ratios are defined under a top-level `metrics` block.

## Metrics

```text
ad_spend
attributed_revenue
new_customers
roas
cac
sessions
purchases
conversion_rate
average_90d_ltv
```

Definitions:

```text
ROAS            = attributed_revenue / ad_spend
CAC             = ad_spend / new_customers
conversion_rate = purchases / sessions
average_90d_ltv = average ltv_90d across customers
```

## Semantic models

`mart_channel_performance` provides channel/month dimensions and the base metrics used by ROAS and CAC.

`mart_funnel` provides channel/day dimensions and the base metrics used by conversion rate.

`mart_customer_ltv` exposes customer, acquisition channel, cohort, first-order date, and 90-day LTV.

## Validate definitions

The latest specification requires dbt Core 1.12+ or the current dbt platform/Fusion runtime.

At minimum:

```bash
dbt parse
```

In dbt Cloud Studio / dbt CLI, also run:

```bash
dbt sl validate
dbt sl list metrics
```

Expected metric names include:

```text
ad_spend
attributed_revenue
roas
new_customers
cac
sessions
purchases
conversion_rate
average_90d_ltv
```

## Query examples

Channel performance:

```bash
dbt sl query \
  --metrics attributed_revenue,ad_spend,roas \
  --group-by metric_time__month,channel
```

Funnel performance:

```bash
dbt sl query \
  --metrics sessions,purchases,conversion_rate \
  --group-by metric_time__day,channel
```

Customer LTV:

```bash
dbt sl query \
  --metrics average_90d_ltv \
  --group-by acquisition_channel
```

If a grouping name differs in the generated semantic manifest, run `dbt sl list dimensions --metrics <metric_name>` and use the dimension name shown by MetricFlow.

## Production deployment

After the pull request is merged, run the normal dbt Cloud Production Build. The deployment job should at least run `dbt parse` (the existing `dbt build` also parses the project) so the semantic manifest reflects the latest metric definitions.

If the account's Semantic Layer is not yet enabled, an account/project administrator must select the production deployment environment under the project's Semantic Layer configuration before downstream tools can query these metrics.

No Semantic Layer service token or credential is committed to GitHub.
