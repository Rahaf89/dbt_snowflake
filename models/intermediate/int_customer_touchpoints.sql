-- One row per (customer, session), ordered, to build attribution paths.
-- Only sessions within the attribution window before an order count.

with events as (

    select *
    from {{ ref('stg_web_events') }}
    where customer_id is not null

),

orders as (

    select *
    from {{ ref('stg_orders') }}

),

touchpoints_before_order as (

    select
        o.order_id,
        o.customer_id,
        o.order_timestamp,
        o.amount_usd,
        e.channel,
        e.event_timestamp,

        row_number() over (
            partition by o.order_id
            order by e.event_timestamp asc
        ) as touch_position_asc,

        row_number() over (
            partition by o.order_id
            order by e.event_timestamp desc
        ) as touch_position_desc,

        count(*) over (
            partition by o.order_id
        ) as total_touches

    from orders o

    inner join events e
        on e.customer_id = o.customer_id
        and e.event_timestamp <= o.order_timestamp
        and e.event_timestamp >= dateadd(
            day,
            -1 * {{ var('attribution_window_days') }},
            o.order_timestamp
        )

)

select *
from touchpoints_before_order