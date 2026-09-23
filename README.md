# Northwind Marketing Analytics with dbt + Snowflake

A production-style analytics engineering project built with **dbt Cloud** and **Snowflake**.

The project transforms raw customer, order, web event, and paid media data into tested analytical models for:

- marketing attribution
- channel performance
- customer lifetime value
- funnel analysis
- ad spend reporting
- customer history tracking with snapshots

## Architecture

```mermaid
flowchart LR
    A[RAW<br/>Snowflake source tables] --> B[PROD_STAGING<br/>cleaned & standardized views]
    B --> C[PROD_INTERMEDIATE<br/>business logic & attribution views]
    C --> D[PROD_MARTS<br/>analytics-ready tables]
    B --> E[SNAPSHOTS<br/>SCD customer history]
    D --> F[BI / Reporting / Analysis]
```

### Snowflake production schemas

```text
NORTHWIND
├── RAW
├── PROD_STAGING
├── PROD_INTERMEDIATE
├── PROD_MARTS
└── SNAPSHOTS
```

Development is isolated from production through dbt development schemas, while scheduled production runs build into the `PROD_*` schemas.

## Tech Stack

- **Snowflake** — cloud data warehouse
- **dbt Cloud** — transformation, testing, documentation, lineage, and orchestration
- **GitHub** — version control and deployment workflow
- **Python + Faker** — synthetic source-data generation
- **SQL / Jinja** — transformation logic

## Source Data

The project uses five raw source tables:

| Source | Purpose |
|---|---|
| `CUSTOMERS` | Customer attributes and acquisition information |
| `ORDERS` | Transactions, revenue, refunds, and order timestamps |
| `WEB_EVENTS` | Customer web activity and marketing touchpoints |
| `GOOGLE_ADS_SPEND` | Google Ads spend |
| `META_ADS_SPEND` | Meta Ads spend |

The source tables live in `NORTHWIND.RAW`.

## dbt Project Structure

```text
models/
├── staging/
│   ├── _sources.yml
│   ├── _staging.yml
│   ├── stg_ad_spend.sql
│   ├── stg_customers.sql
│   ├── stg_orders.sql
│   └── stg_web_events.sql
├── intermediate/
│   ├── int_attributed_revenue.sql
│   └── int_customer_touchpoints.sql
└── marts/
    ├── _marts.yml
    ├── fct_ad_spend.sql
    ├── mart_channel_performance.sql
    ├── mart_customer_ltv.sql
    └── mart_funnel.sql

snapshots/
└── scd_customers.sql

tests/
└── assert_spend_reconciles_to_source.sql
```

## Modeling Layers

### Staging

Production schema: `NORTHWIND.PROD_STAGING`

Models:

- `STG_CUSTOMERS`
- `STG_ORDERS`
- `STG_WEB_EVENTS`
- `STG_AD_SPEND`

### Intermediate

Production schema: `NORTHWIND.PROD_INTERMEDIATE`

Models:

- `INT_CUSTOMER_TOUCHPOINTS`
- `INT_ATTRIBUTED_REVENUE`

### Marts

Production schema: `NORTHWIND.PROD_MARTS`

Models:

- `FCT_AD_SPEND`
- `MART_CHANNEL_PERFORMANCE`
- `MART_CUSTOMER_LTV`
- `MART_FUNNEL`

## Marketing Attribution

The attribution model is configurable through dbt variables:

```yaml
vars:
  attribution_model: "linear"
  attribution_window_days: 30
```

Supported attribution approaches:

- `first_touch`
- `last_touch`
- `linear`

This allows the attribution strategy to be changed without rewriting the underlying model SQL.

## Customer Lifetime Value

`MART_CUSTOMER_LTV` calculates customer revenue during the first **90 days after the first non-refunded order**.

The model also identifies customers whose 90-day LTV window is still incomplete, allowing downstream reporting to exclude immature cohorts when necessary.

## Customer Snapshot

The project uses a dbt snapshot at:

```text
NORTHWIND.SNAPSHOTS.SCD_CUSTOMERS
```

This preserves historical customer changes using a slowly changing dimension pattern.

## Data Quality

The project includes:

- source definitions
- schema tests
- custom data tests
- source freshness checks
- reconciliation testing
- dbt build validation

The project currently includes 10 models, 5 sources, 1 snapshot, 16 data tests, and 1 exposure.

A custom test verifies that modeled advertising spend reconciles with source spend.

## Source Freshness

The `ORDERS` source uses `order_timestamp` as its freshness field.

Production orchestration runs:

```bash
dbt source freshness
dbt build
```

## Production Orchestration

A dbt Cloud production environment is connected to Snowflake using a dedicated `TRANSFORMER` role and key-pair authentication.

The production job performs:

```text
Clone Git repository
        ↓
Create Snowflake profile
        ↓
dbt deps
        ↓
dbt source freshness
        ↓
dbt build
        ↓
Generate dbt documentation
```

The production job is configured for a daily schedule at **07:00 UTC**.

## Snowflake Security

dbt runs with a dedicated transformation role rather than `ACCOUNTADMIN`.

The `TRANSFORMER` role has the permissions needed to:

- use the `NORTHWIND` database
- use the transformation warehouse
- read from `NORTHWIND.RAW`
- create and manage dbt output schemas

Authentication uses an encrypted RSA private key in dbt Cloud, with the corresponding public key registered on the Snowflake user.

## dbt Configuration

The project separates models by layer:

```yaml
models:
  northwind_marketing:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts
```

With `PROD` as the production base schema, dbt generates:

```text
PROD_STAGING
PROD_INTERMEDIATE
PROD_MARTS
```

## Running the Project

Install dependencies:

```bash
dbt deps
```

Build all models, snapshots, and tests:

```bash
dbt build
```

Build only the staging layer:

```bash
dbt build --select staging
```

Run source freshness checks:

```bash
dbt source freshness
```

Clean generated artifacts:

```bash
dbt clean
```

## Example Analytical Questions

This project supports questions such as:

1. Which marketing channels generate the most attributed revenue?
2. How does ad spend compare with attributed revenue by channel?
3. Where do customers drop out of the marketing funnel?
4. What is 90-day customer lifetime value by acquisition channel and cohort?
5. How do first-touch, last-touch, and linear attribution change channel performance?

## Development Workflow

```text
Feature branch
      ↓
dbt Cloud Studio
      ↓
dbt build + tests
      ↓
Pull request
      ↓
Merge to main
      ↓
Production dbt Cloud job
      ↓
Snowflake PROD_* schemas
```

## Project Highlights

- Layered dbt architecture
- Separate development and production schemas
- Configurable marketing attribution
- Source freshness monitoring
- Automated dbt tests
- Custom reconciliation test
- SCD snapshot implementation
- Snowflake key-pair authentication
- Dedicated transformation role
- Git-based deployment
- Scheduled dbt Cloud production job
- Generated dbt documentation and lineage

## Future Improvements

- add CI jobs for pull requests
- add incremental models for large event tables
- expose marts to Looker or another BI tool
- add anomaly detection for spend and conversion metrics
- create dbt Semantic Layer metrics
- add warehouse cost monitoring and query optimization
- add alerting for failed production runs or freshness failures
