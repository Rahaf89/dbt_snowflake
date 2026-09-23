-- Splits each order's revenue across its touchpoints according to
-- var('attribution_model'): first_touch | last_touch | linear.
-- Switching the var (dbt run --vars 'attribution_model: first_touch')
-- changes this whole model with no SQL edits, which is what the
-- attribution-comparison dashboard page compares side by side.
{% set model_choice = var('attribution_model') %}

with touchpoints as (
    select * from {{ ref('int_customer_touchpoints') }}
),

credited as (
    select
        order_id,
        customer_id,
        order_timestamp,
        channel,
        amount_usd,
        total_touches,
        {% if model_choice == 'first_touch' %}
            case when touch_position_asc = 1 then 1.0 else 0.0 end
        {% elif model_choice == 'last_touch' %}
            case when touch_position_desc = 1 then 1.0 else 0.0 end
        {% else %}
            -- linear: equal credit across every touch
            1.0 / total_touches
        {% endif %} as credit_fraction
    from touchpoints
)

select
    order_id,
    customer_id,
    order_timestamp,
    channel,
    round(amount_usd * credit_fraction, 4) as attributed_revenue,
    '{{ model_choice }}' as attribution_model
from credited
where credit_fraction > 0
