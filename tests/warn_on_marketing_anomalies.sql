{{ config(severity='warn') }}

-- This test intentionally warns instead of failing the production build.
-- Detected rows remain queryable in MON_MARKETING_ANOMALIES for investigation.

select *
from {{ ref('mon_marketing_anomalies') }}
where is_any_anomaly
