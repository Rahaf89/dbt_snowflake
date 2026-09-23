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

## MetricFlow time spine

The project includes `models/marts/time_spine_daily.sql` plus `_time_spine.yml`. MetricFlow requires a daily-or-finer time spine for time-based metrics and joins. The model covers recent history plus a short future window and is materialized as a table.

Build it in development with:

```bash
dbt run --select time_spine_daily
```

## Semantic models

### Explicit grain entities

MetricFlow semantic models need an unambiguous primary grain. The monthly channel mart exposes `channel_month_key` as the primary entity, while the daily funnel mart exposes `channel_day_key`. Both are deterministic dbt-utils surrogate keys built from the natural composite grain. The time columns use `performance_month` and `funnel_date` rather than reserved granularity words such as `month` or `day`.


`mart_channel_performance` provides channel/month dimensions and the base metrics used by ROAS and CAC.

`mart_funnel` provides channel/day dimensions and the base metrics used by conversion rate.

`mart_customer_ltv` exposes customer, acquisition channel, cohort, first-order date, and 90-day LTV.

## Validate definitions

The latest specification requires dbt Core 1.12+ or the current dbt platform/Fusion runtime.

First build the time spine:

```bash
dbt run --select time_spine_daily
```

Then validate the semantic definitions locally in the project:

```bash
dbt parse
```

A successful `dbt parse` is the **pre-merge validation** for the Semantic Layer configuration. It checks that the semantic YAML, entities, time dimensions, metrics, and MetricFlow time spine can be parsed into a valid semantic manifest.

Do **not** use `dbt sl validate` as the pre-merge branch check in this project. That command queries the dbt Semantic Layer API, which reads the semantic manifest published by the configured deployment environment. Before this feature branch is merged and a successful production deployment publishes the new manifest, the API can return:

```text
Empty semantic manifest was found.
Ensure that you have semantic models defined.
```

That message does not mean the branch YAML is empty; it means the Semantic Layer service has not yet received a production semantic manifest containing these new definitions.

### Publish and validate through dbt Cloud

After the pull request is merged:

1. Run the normal dbt Cloud **Production Build** successfully so the deployment environment generates fresh dbt artifacts containing the semantic definitions.
2. In the project's Semantic Layer settings, select the **Production** deployment environment if it is not already configured.
3. Then run:

```bash
dbt sl validate
dbt sl list metrics
```

At this point the Semantic Layer API should be reading the published production semantic manifest rather than an empty one.

If the account does not expose Semantic Layer configuration or `dbt sl` API access, the project can still keep the version-controlled semantic definitions and validate them with `dbt parse`; API querying requires the corresponding dbt platform capability to be enabled.

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
