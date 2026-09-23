-- Rolling anomaly detection for spend, attributed revenue, and conversion rate.
-- The current row is excluded from its baseline to avoid self-influence.

{% set lookback = var('anomaly_lookback_periods', 28) %}
{% set min_history = var('anomaly_min_history_periods', 7) %}
{% set threshold = var('anomaly_zscore_threshold', 3.0) %}

with daily as (

    select *
    from {{ ref('mon_marketing_daily_metrics') }}

),

baselines as (

    select
        *,

        count(daily_spend) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as spend_history_periods,

        avg(daily_spend) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as spend_baseline_avg,

        stddev_samp(daily_spend) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as spend_baseline_stddev,

        count(attributed_revenue) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as revenue_history_periods,

        avg(attributed_revenue) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as revenue_baseline_avg,

        stddev_samp(attributed_revenue) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as revenue_baseline_stddev,

        count(conversion_rate) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as conversion_history_periods,

        avg(conversion_rate) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as conversion_baseline_avg,

        stddev_samp(conversion_rate) over (
            partition by channel
            order by metric_date
            rows between {{ lookback }} preceding and 1 preceding
        ) as conversion_baseline_stddev

    from daily

),

scores as (

    select
        *,

        case
            when spend_history_periods >= {{ min_history }}
             and spend_baseline_stddev > 0
             and daily_spend is not null
            then (daily_spend - spend_baseline_avg) / spend_baseline_stddev
        end as spend_zscore,

        case
            when revenue_history_periods >= {{ min_history }}
             and revenue_baseline_stddev > 0
             and attributed_revenue is not null
            then (attributed_revenue - revenue_baseline_avg) / revenue_baseline_stddev
        end as revenue_zscore,

        case
            when conversion_history_periods >= {{ min_history }}
             and conversion_baseline_stddev > 0
             and conversion_rate is not null
            then (conversion_rate - conversion_baseline_avg) / conversion_baseline_stddev
        end as conversion_rate_zscore

    from baselines

),

flags as (

    select
        *,

        coalesce(abs(spend_zscore) >= {{ threshold }}, false) as spend_anomaly,
        coalesce(abs(revenue_zscore) >= {{ threshold }}, false) as revenue_anomaly,
        coalesce(abs(conversion_rate_zscore) >= {{ threshold }}, false) as conversion_rate_anomaly

    from scores

)

select
    *,
    spend_anomaly
        or revenue_anomaly
        or conversion_rate_anomaly as is_any_anomaly

from flags
