-- One row per channel, per day.
-- Keeps raw daily observations separate from the anomaly-scoring model.

with spend as (

    select
        cast(spend_date as date) as metric_date,
        channel,
        sum(spend) as daily_spend
    from {{ ref('fct_ad_spend') }}
    group by 1, 2

),

revenue as (

    select
        cast(order_timestamp as date) as metric_date,
        channel,
        sum(attributed_revenue) as attributed_revenue
    from {{ ref('int_attributed_revenue') }}
    group by 1, 2

),

funnel as (

    select
        cast(funnel_date as date) as metric_date,
        channel,
        sum(sessions) as sessions,
        sum(purchases) as purchases
    from {{ ref('mart_funnel') }}
    group by 1, 2

),

keys as (

    select metric_date, channel from spend
    union
    select metric_date, channel from revenue
    union
    select metric_date, channel from funnel

)

select
    k.metric_date,
    k.channel,
    s.daily_spend,
    r.attributed_revenue,
    f.sessions,
    f.purchases,
    round(
        f.purchases / nullif(f.sessions, 0),
        6
    ) as conversion_rate

from keys k

left join spend s
    on k.metric_date = s.metric_date
   and k.channel = s.channel

left join revenue r
    on k.metric_date = r.metric_date
   and k.channel = r.channel

left join funnel f
    on k.metric_date = f.metric_date
   and k.channel = f.channel
