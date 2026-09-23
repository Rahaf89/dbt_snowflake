-- Key-pair authentication template for the dbt Snowflake user.
-- DO NOT commit a private key or passphrase to GitHub.
-- See snowflake/README.md for the full OpenSSL + dbt Cloud setup.

USE ROLE ACCOUNTADMIN;

-- Paste only the PUBLIC key body:
--   * no -----BEGIN PUBLIC KEY-----
--   * no -----END PUBLIC KEY-----
--   * no line breaks
ALTER USER RAHAF
SET RSA_PUBLIC_KEY='<PUBLIC_KEY_WITHOUT_PEM_HEADERS_OR_LINE_BREAKS>';

-- Verify that Snowflake has a key registered:
DESC USER RAHAF;

-- Look for RSA_PUBLIC_KEY_FP in the result.
