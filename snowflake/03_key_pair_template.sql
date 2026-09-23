-- Key-pair authentication template for the dbt Snowflake user.
-- DO NOT commit a private key or passphrase to GitHub.
-- Replace the placeholders locally before running.

USE ROLE ACCOUNTADMIN;

-- Example:
-- ALTER USER <DBT_USER>
--   SET RSA_PUBLIC_KEY='<PUBLIC_KEY_WITHOUT_PEM_HEADERS_OR_LINE_BREAKS>';

-- Verify that Snowflake has a key registered:
-- DESC USER <DBT_USER>;
--
-- Look for RSA_PUBLIC_KEY_FP in the result.
