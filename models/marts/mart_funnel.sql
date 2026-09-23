-- Grain: one row per channel, per day. Answers business question 5.
with daily as (

    select
        cast(date_trunc('day', event_timestamp) as date) as funnel_date,
        channel,
        count(distinct case when event_type = 'page_view'   then session_id end) as sessions,
        count(distinct case when event_type = 'add_to_cart' then session_id end) as add_to_carts,
        count(distinct case when event_type = 'purchase'    then session_id end) as purchases
    from {{ ref('stg_web_events') }}
    group by 1, 2

)

select
    {{ dbt_utils.generate_surrogate_key(['funnel_date', 'channel']) }} as channel_day_key,
    *
from daily
