-- Unifies Google Ads and Meta Ads spend into one shape, fixing:
--   * inconsistent campaign_name casing / stray whitespace
--   * duplicate rows from platform export re-runs (dedup via row_number)
with google as (
    select
        date, platform, campaign_id, campaign_name,
        impressions, clicks, spend
    from {{ source('raw', 'google_ads_spend') }}
),

meta as (
    select
        date, platform, campaign_id, campaign_name,
        impressions, clicks, spend
    from {{ source('raw', 'meta_ads_spend') }}
),

unioned as (
    select * from google
    union all
    select * from meta
),

normalized as (
    select
        cast(date as date)          as spend_date,
        platform,
        campaign_id,
        -- standardize casing/whitespace so the same campaign doesn't
        -- fragment into multiple rows downstream
        trim(lower(campaign_name))  as campaign_name,
        impressions,
        clicks,
        spend
    from unioned
),

deduped as (
    select *,
        row_number() over (
            partition by spend_date, platform, campaign_id, impressions, clicks, spend
            order by spend_date
        ) as rn
    from normalized
)

select
    spend_date, platform, campaign_id, campaign_name,
    impressions, clicks, spend
from deduped
where rn = 1
