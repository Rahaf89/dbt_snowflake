-- Grain: one row per channel, per month. Answers business questions 1-2.
with spend as (
    select
        date_trunc('month', spend_date) as month,
        channel,
        sum(spend) as total_spend
    from {{ ref('fct_ad_spend') }}
    group by 1, 2
),

revenue as (
    select
        date_trunc('month', order_timestamp) as month,
        channel,
        sum(attributed_revenue) as total_attributed_revenue,
        count(distinct order_id) as attributed_orders
    from {{ ref('int_attributed_revenue') }}
    group by 1, 2
),

new_customers as (
    select
        date_trunc('month', signup_date) as month,
        acquisition_channel as channel,
        count(distinct customer_id) as new_customers
    from {{ ref('stg_customers') }}
    group by 1, 2
)

select
    coalesce(s.month, r.month, nc.month)       as month,
    coalesce(s.channel, r.channel, nc.channel) as channel,
    s.total_spend,
    r.total_attributed_revenue,
    r.attributed_orders,
    nc.new_customers,
    round(r.total_attributed_revenue / nullif(s.total_spend, 0), 2)   as roas,
    round(s.total_spend / nullif(nc.new_customers, 0), 2)             as cac
from spend s
full outer join revenue r
    on s.month = r.month and s.channel = r.channel
full outer join new_customers nc
    on coalesce(s.month, r.month) = nc.month
    and coalesce(s.channel, r.channel) = nc.channel
