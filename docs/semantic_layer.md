# dbt Semantic Layer

The project uses the dbt Semantic Layer / MetricFlow to keep important marketing definitions in one governed location instead of reimplementing them separately in dashboards.

## Metrics

```text
ad_spend
attributed_revenue
new_customers
roas
cac
sessions
purchases
conversion_rate
average_90d_ltv
```

Definitions:

```text
ROAS            = attributed_revenue / ad_spend
CAC             = ad_spend / new_customers
conversion_rate = purchases / sessions
average_90d_ltv = average ltv_90d across customers
```

## Semantic model structure

The latest semantic definitions live in `models/marts/_marts.yml`.

The semantic models are based on:

- `mart_channel_performance` — channel/month metrics such as spend, attributed revenue, ROAS, CAC, and new customers
- `mart_funnel` — channel/day metrics such as sessions, purchases, and conversion rate
- `mart_customer_ltv` — customer-level 90-day LTV

MetricFlow needs an explicit, unambiguous grain. The project therefore exposes:

```text
channel_month_key
channel_day_key
customer_id
```

as primary entities for the relevant semantic models.

The time dimensions are:

```text
performance_month
funnel_date
first_order_at
cohort_month
```

The project deliberately avoids naming semantic time columns simply `month` or `day`, because those words are reserved time-granularity keywords in MetricFlow.

## MetricFlow time spine

MetricFlow requires a daily-or-finer time spine for time-based metric aggregation and joins.

The project includes:

```text
models/marts/time_spine_daily.sql
models/marts/_time_spine.yml
```

Build it in development with:

```bash
dbt run --select time_spine_daily
```

Then validate the semantic definitions locally:

```bash
dbt parse
```

A successful `dbt parse` is the main **pre-merge** validation. It checks that the semantic YAML, entities, time dimensions, metrics, and MetricFlow time spine can be parsed into a valid semantic manifest.

## Complete dbt Cloud Semantic Layer setup

The Semantic Layer API does not automatically use whichever environment is open in dbt Cloud Studio. It must be configured from the dbt Cloud account/project settings.

### 1. Merge the semantic definitions and run Production Build

First merge the Semantic Layer changes into `main`.

Then run the normal dbt Cloud **Production Build** so the Production deployment environment generates fresh dbt artifacts containing the semantic manifest.

The production job remains:

```text
dbt deps
    ↓
dbt source freshness
    ↓
dbt build
    ↓
generate dbt documentation
```

### 2. Select Production as the Semantic Layer environment

In dbt Cloud:

```text
Account settings
    ↓
Projects
    ↓
NORTHWIND ANALYTICS
    ↓
Semantic Layer / Semantic Layer Configuration
    ↓
Deployment environment = Production
```

The Semantic Layer must point to the existing **Production** deployment environment.

Do not create a second production environment just for the Semantic Layer.

Also, the **Defer to: DEV** selector shown in dbt Cloud Studio is unrelated to this configuration. It can remain `DEV`; the Semantic Layer deployment environment is selected separately under the project/account Semantic Layer settings.

### 3. Create the Snowflake Semantic Layer credential

Under:

```text
Semantic Layer Configuration
    ↓
Credentials & tokens
    ↓
Create new Semantic Layer credential
```

use a descriptive name such as:

```text
northwind-semantic-layer-prod
```

For this project:

```text
Username:   RAHAF
Role:       TRANSFORMER
Warehouse:  TRANSFORM_WH_XS
Auth:       key-pair / private-key authentication
```

The database/project relationship is already provided by the dbt Cloud environment configuration.

### 4. Key-pair authentication

The Semantic Layer credential should use Snowflake RSA key-pair authentication rather than a plain Snowflake password.

A dedicated Semantic Layer key can be generated with OpenSSL.

Generate the unencrypted PKCS#8 private key:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" genrsa 2048 |
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" pkcs8 `
  -topk8 `
  -inform PEM `
  -out semantic_layer_key.p8 `
  -nocrypt
```

Generate the public key:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" rsa `
  -in semantic_layer_key.p8 `
  -pubout `
  -out semantic_layer_key.pub
```

Encrypt the private key:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" pkcs8 `
  -topk8 `
  -inform PEM `
  -outform PEM `
  -in semantic_layer_key.p8 `
  -out semantic_layer_key_encrypted.p8
```

OpenSSL asks for an encryption password. That password is the **private-key passphrase** used in the dbt Cloud Semantic Layer credential.

Never commit the private key or passphrase.

### 5. Register the public key in Snowflake

Display the public key:

```powershell
Get-Content .\semantic_layer_key.pub
```

Convert it to the single-line value Snowflake expects:

```powershell
(Get-Content .\semantic_layer_key.pub |
    Where-Object { $_ -notmatch "PUBLIC KEY" }) -join ""
```

Register it as Snowflake's second RSA key so the existing dbt production key does not need to be replaced:

```sql
USE ROLE ACCOUNTADMIN;

ALTER USER RAHAF
SET RSA_PUBLIC_KEY_2='<PUBLIC_KEY_WITHOUT_HEADERS_OR_LINE_BREAKS>';
```

Verify:

```sql
DESC USER RAHAF;
```

Confirm that `RSA_PUBLIC_KEY_2_FP` is populated.

Snowflake supports two RSA public-key slots, which is useful for separate credentials and key rotation.

### 6. Enter the encrypted private key in dbt Cloud

Use the full contents of:

```text
semantic_layer_key_encrypted.p8
```

To copy it from PowerShell:

```powershell
Get-Content .\semantic_layer_key_encrypted.p8 -Raw
```

Paste the full PEM block into dbt Cloud:

```text
-----BEGIN ENCRYPTED PRIVATE KEY-----
...
-----END ENCRYPTED PRIVATE KEY-----
```

Then enter the passphrase created when the private key was encrypted.

Do not paste either value into GitHub, README files, tickets, or chat messages.

### 7. Create and map the Semantic Layer service token

Under **Map new service token**, use a descriptive token name such as:

```text
northwind-semantic-layer
```

Keep the permission sets:

```text
Semantic Layer Only
Metadata Only
```

with:

```text
Environment write access: None
```

The token is for consumers of the Semantic Layer. Save its value securely when dbt Cloud displays it; do not commit it to the repository.

## Validation and testing

### Pre-merge validation

Before merge:

```bash
dbt run --select time_spine_daily
dbt parse
```

Do not treat `dbt sl validate` as the branch-level parser check. The `dbt sl` commands call the dbt Semantic Layer API and therefore depend on a semantic manifest already published by the configured deployment environment.

Before Production is configured/published, the API can return:

```text
Empty semantic manifest was found.
Ensure that you have semantic models defined.
```

That does not mean the branch YAML is empty. It means the Semantic Layer service has no deployed semantic manifest to query yet.

### Post-merge / production validation

After the Production Build has completed and the Semantic Layer credential/token are configured:

```bash
dbt sl validate
```

Then list metrics:

```bash
dbt sl list metrics
```

Expected names include:

```text
ad_spend
attributed_revenue
roas
new_customers
cac
sessions
purchases
conversion_rate
average_90d_ltv
```

Then query the Semantic Layer:

```bash
dbt sl query \
  --metrics attributed_revenue,ad_spend,roas \
  --group-by metric_time__month,channel
```

Additional examples:

```bash
dbt sl query \
  --metrics sessions,purchases,conversion_rate \
  --group-by metric_time__day,channel
```

```bash
dbt sl query \
  --metrics average_90d_ltv \
  --group-by acquisition_channel
```

If a grouping name differs from the example, inspect available dimensions with:

```bash
dbt sl list dimensions --metrics <metric_name>
```

## Troubleshooting steps used in this project

### Empty semantic manifest

Symptom:

```text
Empty semantic manifest was found.
Ensure that you have semantic models defined.
```

Resolution:

1. Confirm the semantic definitions have been merged into `main`.
2. Run a successful Production Build.
3. Open Account settings → Projects → NORTHWIND ANALYTICS → Semantic Layer.
4. Select **Production** as the Semantic Layer deployment environment.
5. Create the Snowflake Semantic Layer credential.
6. Create/map the service token.
7. Run the Production Build again after the Semantic Layer configuration is complete.
8. Retry `dbt sl validate`.

### Invalid identifiers such as PERFORMANCE_MONTH or FUNNEL_DATE

Symptoms included:

```text
invalid identifier 'PERFORMANCE_MONTH'
invalid identifier 'FUNNEL_DATE'
invalid identifier 'CHANNEL_MONTH_KEY'
invalid identifier 'CHANNEL_DAY_KEY'
```

First verify the actual Snowflake production columns:

```sql
SELECT
    table_schema,
    table_name,
    column_name,
    ordinal_position
FROM NORTHWIND.INFORMATION_SCHEMA.COLUMNS
WHERE table_name IN (
    'MART_CHANNEL_PERFORMANCE',
    'MART_FUNNEL'
)
ORDER BY table_schema, table_name, ordinal_position;
```

The expected production columns include:

```text
MART_CHANNEL_PERFORMANCE
  CHANNEL_MONTH_KEY
  PERFORMANCE_MONTH

MART_FUNNEL
  CHANNEL_DAY_KEY
  FUNNEL_DATE
```

If the warehouse tables are already correct, do not rebuild them unnecessarily. Rerun the normal Production Build after the Semantic Layer configuration is complete so the published semantic manifest and warehouse relations are aligned.

### Final successful state

For this project the final validation completed successfully:

```text
dbt sl validate        ✅
dbt sl list metrics    ✅
dbt sl query ...       ✅
```

The working sequence was:

```text
semantic models + metrics in Git
        ↓
dbt parse
        ↓
merge to main
        ↓
Production Build
        ↓
Account settings → Semantic Layer → Production
        ↓
Snowflake key-pair credential
        ↓
Semantic Layer Only + Metadata Only service token
        ↓
Production Build / manifest refresh
        ↓
dbt sl validate
        ↓
dbt sl list metrics
        ↓
dbt sl query
```

## Security

Never commit or expose:

```text
semantic_layer_key.p8
semantic_layer_key_encrypted.p8
private-key passphrase
Semantic Layer service-token value
Snowflake passwords
dbt Cloud tokens
```

Only the public key is registered in Snowflake.

The repository's `.gitignore` excludes private-key file extensions and common secret files.
