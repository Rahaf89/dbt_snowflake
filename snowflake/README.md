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
