-- Query-performance telemetry for the project's Snowflake warehouse.
-- The model intentionally does not persist QUERY_TEXT because SQL text can
-- occasionally contain sensitive literals.

select
    query_id,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    warehouse_size,
    execution_status,
    query_tag,
    start_time,
    end_time,

    total_elapsed_time as total_elapsed_ms,
    round(total_elapsed_time / 1000.0, 2) as total_elapsed_seconds,

    bytes_scanned,
    round(bytes_scanned / power(1024, 3), 4) as gb_scanned,

    round(percentage_scanned_from_cache * 100, 2) as cache_hit_pct

from {{ source('snowflake_account_usage', 'query_history') }}

where warehouse_name = upper('{{ var("monitored_warehouse", "TRANSFORM_WH_XS") }}')
  and start_time >= dateadd(
      day,
      -1 * {{ var('monitoring_lookback_days', 30) }},
      current_timestamp()
  )
