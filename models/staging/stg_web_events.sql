-- Excludes bot traffic (see docs/data_quality_log.md) so downstream
-- conversion-rate and channel metrics aren't inflated.
with source as (
    select * from {{ source('raw', 'web_events') }}
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

select * from cleaned
