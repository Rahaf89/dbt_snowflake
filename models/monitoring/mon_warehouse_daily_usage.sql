-- Daily warehouse credit usage and an estimate of compute spent while no
-- query was actively executing.
--
-- CREDITS_USED is consumption, not necessarily the final billed amount because
-- Snowflake can apply cloud-services adjustments at the account/day level.

with hourly_usage as (

    select
        start_time,
        warehouse_name,
        credits_used,
        credits_used_compute,
        credits_used_cloud_services,
        credits_attributed_compute_queries

    from {{ source('snowflake_account_usage', 'warehouse_metering_history') }}

    where warehouse_name = upper('{{ var("monitored_warehouse", "TRANSFORM_WH_XS") }}')
      and start_time >= dateadd(
          day,
          -1 * {{ var('monitoring_lookback_days', 30) }},
          current_timestamp()
      )

),

daily as (

    select
        cast(date_trunc('day', start_time) as date) as usage_date,
        warehouse_name,

        round(sum(credits_used), 4) as credits_used,
        round(sum(credits_used_compute), 4) as compute_credits,
        round(sum(credits_used_cloud_services), 4) as cloud_services_credits,
        round(sum(credits_attributed_compute_queries), 4) as query_attributed_credits,

        round(
            greatest(
                sum(credits_used_compute) - sum(credits_attributed_compute_queries),
                0
            ),
            4
        ) as estimated_idle_credits

    from hourly_usage
    group by 1, 2

)

select
    usage_date,
    warehouse_name,
    credits_used,
    compute_credits,
    cloud_services_credits,
    query_attributed_credits,
    estimated_idle_credits,

    round(
        100 * estimated_idle_credits / nullif(compute_credits, 0),
        2
    ) as estimated_idle_pct

from daily
