-- The raw sources have a ~2% duplicate-row rate injected deliberately
-- (see ingestion/generate_data.py), so fct_ad_spend's total should sit a
-- bit below the raw total (dedup working) but not far below it (dedup
-- not over-deleting). Fails outside a 90-100% band of the raw total.
with raw_total as (
    select sum(spend) as total from {{ source('raw', 'google_ads_spend') }}
    union all
    select sum(spend) as total from {{ source('raw', 'meta_ads_spend') }}
),

raw_summed as (
    select sum(total) as raw_total_spend from raw_total
),

mart_summed as (
    select sum(spend) as mart_total_spend from {{ ref('fct_ad_spend') }}
)

select *
from raw_summed, mart_summed
where mart_total_spend > raw_total_spend                       -- over-counted (dedup failed)
   or mart_total_spend < raw_total_spend * 0.90                 -- under-counted (dedup too aggressive)
