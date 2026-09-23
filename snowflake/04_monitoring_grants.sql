-- Allow the dbt TRANSFORMER role to read historical Snowflake usage data.
-- Run once as ACCOUNTADMIN (or another role allowed to grant SNOWFLAKE database roles).
--
-- This grants read-only access to usage/history views such as:
--   SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
--   SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
--
-- It does NOT grant permission to administer warehouses or billing settings.

USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER TO ROLE TRANSFORMER;

-- Optional verification:
SHOW GRANTS TO ROLE TRANSFORMER;
