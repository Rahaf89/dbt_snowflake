-- Grain: one row per platform, campaign, day.
select
    spend_date,
    platform as channel,
    campaign_id,
    campaign_name,
    impressions,
    clicks,
    spend
from {{ ref('stg_ad_spend') }}
