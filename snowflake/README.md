# Snowflake setup

This folder contains the Snowflake side of the Northwind Marketing Analytics project.

## Run order

1. Run `01_setup.sql` as `ACCOUNTADMIN` (or an equivalent administrative role).
2. Run `02_raw_tables.sql`.
3. Load the five synthetic CSV files into `NORTHWIND.RAW`.
4. Configure key-pair authentication using `03_key_pair_template.sql`.
5. Configure dbt Cloud to use:
   - Database: `NORTHWIND`
   - Warehouse: `TRANSFORM_WH_XS`
   - Role: `TRANSFORMER`
   - Development base schema: a personal dbt schema
   - Production base schema: `PROD`

## Load the CSV files into Snowflake

First generate the sample files from the repository root:

```bash
cd ingestion
pip install -r requirements.txt
python generate_data.py --out ../raw_data
```

This creates:

| Local CSV | Snowflake target table |
|---|---|
| `raw_data/customers.csv` | `NORTHWIND.RAW.CUSTOMERS` |
| `raw_data/orders.csv` | `NORTHWIND.RAW.ORDERS` |
| `raw_data/web_events.csv` | `NORTHWIND.RAW.WEB_EVENTS` |
| `raw_data/google_ads_spend.csv` | `NORTHWIND.RAW.GOOGLE_ADS_SPEND` |
| `raw_data/meta_ads_spend.csv` | `NORTHWIND.RAW.META_ADS_SPEND` |

### Load with Snowsight

Repeat these steps for each CSV:

1. Open **Snowsight** and select the `NORTHWIND` database.
2. Open the `RAW` schema.
3. Choose **Add Data** / **Load files into a table**.
4. Upload one CSV from the local `raw_data/` folder.
5. Select the matching **existing table** from the mapping above.
6. Use CSV parsing with:
   - comma delimiter
   - the first row treated as column headers
   - standard double-quote text enclosure when detected
7. Review the column mapping and load the file.
8. Repeat until all five source tables are populated.

The table definitions are already created by `02_raw_tables.sql`, so the loader should target those existing tables rather than creating different table names.

### Verify the load

Run:

```sql
USE DATABASE NORTHWIND;
USE SCHEMA RAW;

SELECT COUNT(*) AS customers       FROM CUSTOMERS;
SELECT COUNT(*) AS orders          FROM ORDERS;
SELECT COUNT(*) AS web_events      FROM WEB_EVENTS;
SELECT COUNT(*) AS google_ad_rows  FROM GOOGLE_ADS_SPEND;
SELECT COUNT(*) AS meta_ad_rows    FROM META_ADS_SPEND;
```

All five counts should be greater than zero before running dbt.

> For this portfolio project, the initial raw-data load is intentionally simple and manual. The optional Airflow layer in `airflow/` can be extended later to automate ingestion before triggering the dbt Cloud production job.

## Snowflake ↔ dbt Cloud key-pair authentication

This project uses **RSA key-pair authentication** instead of storing the Snowflake password in dbt Cloud.

### 1. Install / locate OpenSSL on Windows

In this setup, OpenSSL was installed at:

```text
C:\Program Files\OpenSSL-Win64\bin\openssl.exe
```

Verify it from PowerShell:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" version
```

### 2. Generate the RSA private key

First generate a PKCS#8 private key:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" genrsa 2048 |
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" pkcs8 `
  -topk8 `
  -inform PEM `
  -out rsa_key.p8 `
  -nocrypt
```

Then create the matching public key:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" rsa `
  -in rsa_key.p8 `
  -pubout `
  -out rsa_key.pub
```

At this point:

```text
rsa_key.p8   = private key
rsa_key.pub  = public key
```

### 3. Encrypt the private key for dbt Cloud

dbt Cloud requires the private key to be encrypted.

Convert the private key into an encrypted PKCS#8 key:

```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" pkcs8 `
  -topk8 `
  -inform PEM `
  -outform PEM `
  -in rsa_key.p8 `
  -out rsa_key_encrypted.p8
```

OpenSSL prompts for:

```text
Enter Encryption Password:
Verifying - Enter Encryption Password:
```

That password is the **private-key passphrase** used later in dbt Cloud.

Important:

- choose your own strong passphrase
- store it in a password manager or secret manager
- never commit it to GitHub
- never commit the private key
- if the private key or passphrase is exposed, rotate the key pair

### 4. Register the public key in Snowflake

Get the public key:

```powershell
Get-Content .\rsa_key.pub
```

For Snowflake, remove the PEM header/footer and line breaks.

A PowerShell helper:

```powershell
(Get-Content .\rsa_key.pub |
    Where-Object { $_ -notmatch "PUBLIC KEY" }) -join ""
```

Then run in Snowflake as a role that can alter the user:

```sql
USE ROLE ACCOUNTADMIN;

ALTER USER RAHAF
SET RSA_PUBLIC_KEY='<PUBLIC_KEY_WITHOUT_HEADERS_OR_LINE_BREAKS>';
```

Verify the key fingerprint:

```sql
DESC USER RAHAF;
```

Look for `RSA_PUBLIC_KEY_FP`.

### 5. Configure dbt Cloud

In dbt Cloud, choose **Key pair** authentication.

| dbt Cloud field | Value |
|---|---|
| Account | your Snowflake account identifier |
| Database | `NORTHWIND` |
| Warehouse | `TRANSFORM_WH_XS` |
| Role | `TRANSFORMER` |
| Username | `RAHAF` |
| Auth method | `Key pair` |
| Private key | full contents of `rsa_key_encrypted.p8` |
| Private key passphrase | the password chosen in step 3 |
| Development schema | personal development schema, e.g. `DBT_ANALYTICS` |
| Production base schema | `PROD` |

To copy the encrypted private key:

```powershell
Get-Content .\rsa_key_encrypted.p8 -Raw
```

Paste the entire block into dbt Cloud, including:

```text
-----BEGIN ENCRYPTED PRIVATE KEY-----
...
-----END ENCRYPTED PRIVATE KEY-----
```

### Security note

The **public key** is safe to register in Snowflake.

The following must remain secret:

```text
rsa_key.p8
rsa_key_encrypted.p8
private-key passphrase
Snowflake passwords / tokens
dbt Cloud tokens
```

These are excluded from the repository through `.gitignore`.

## Production schemas

dbt creates these from the production base schema and the layer-specific schema configuration in `dbt_project.yml`:

```text
NORTHWIND
├── RAW
├── PROD_STAGING
├── PROD_INTERMEDIATE
├── PROD_MARTS
└── SNAPSHOTS
```

## Source tables

```text
NORTHWIND.RAW.CUSTOMERS
NORTHWIND.RAW.ORDERS
NORTHWIND.RAW.WEB_EVENTS
NORTHWIND.RAW.GOOGLE_ADS_SPEND
NORTHWIND.RAW.META_ADS_SPEND
```

Never commit Snowflake passwords, private RSA keys, private-key passphrases, or account secrets to this repository.
