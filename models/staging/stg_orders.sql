-- Normalizes all order amounts to USD using fixed rates.
-- In production this would join a daily fx-rate table instead of
-- hardcoded constants; noted as a decision in the README.
with source as (
    select * from {{ source('raw', 'orders') }}
),

fx as (
    select 'USD' as currency, 1.0    as usd_rate union all
    select 'EUR' as currency, 1.08   as usd_rate union all
    select 'GBP' as currency, 1.27   as usd_rate
),

cleaned as (
    select
        o.order_id,
        o.customer_id,
        cast(o.order_timestamp as timestamp) as order_timestamp,
        round(o.amount * fx.usd_rate, 2)     as amount_usd,
        o.is_refunded
    from source o
    left join fx on o.currency = fx.currency
    where o.customer_id is not null
)

select * from cleaned
