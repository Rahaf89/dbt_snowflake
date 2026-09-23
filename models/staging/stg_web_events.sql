{{
    config(
        materialized='incremental',
        unique_key='event_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

-- High-volume event data is incremental so normal runs only reprocess a
-- configurable lookback window instead of scanning the entire RAW table.
-- The merge strategy uses event_id to avoid duplicates while allowing
-- late-arriving events inside the lookback window to be picked up.

with source as (

    select *
    from {{ source('raw', 'web_events') }}

    {% if is_incremental() %}
        where cast(event_timestamp as timestamp) >= dateadd(
            day,
            -1 * {{ var('event_lookback_days', 3) }},
            (
                select coalesce(
                    max(event_timestamp),
                    '1900-01-01'::timestamp
                )
                from {{ this }}
            )
        )
    {% endif %}

),

cleaned as (

    select
        event_id,
        session_id,
        customer_id,
        cast(event_timestamp as timestamp) as event_timestamp,
        channel,
        event_type
    from source
    where is_bot = false

)

select *
from cleaned
