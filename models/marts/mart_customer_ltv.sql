-- Grain: one row per customer. Answers business question 4.
-- LTV window is capped at 90 days from first order; customers acquired
-- less than 90 days ago are flagged so the dashboard can exclude them
-- from cohort averages (their LTV is still accumulating).
with first_order as (
    select
        customer_id,
        min(order_timestamp) as first_order_at
    from {{ ref('stg_orders') }}
    where is_refunded = false
    group by 1
),

revenue_90d as (
    select
        o.customer_id,
        sum(o.amount_usd) as revenue_90d
    from {{ ref('stg_orders') }} o
    inner join first_order fo on fo.customer_id = o.customer_id
    where o.order_timestamp <= {{ dbt_utils.dateadd('day', 90, 'fo.first_order_at') }}
      and o.is_refunded = false
    group by 1
)

select
    c.customer_id,
    c.acquisition_channel,
    date_trunc('month', fo.first_order_at) as cohort_month,
    fo.first_order_at,
    coalesce(r.revenue_90d, 0) as ltv_90d,
    (current_date - fo.first_order_at::date) < 90 as ltv_still_accumulating
from {{ ref('stg_customers') }} c
inner join first_order fo on fo.customer_id = c.customer_id
left join revenue_90d r on r.customer_id = c.customer_id
