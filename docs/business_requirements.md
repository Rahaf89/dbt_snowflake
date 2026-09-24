# Business Problem & Requirements

## Project context

This repository represents an end-to-end **analytics engineering delivery**, beginning with a simulated client/business request and ending with a tested Snowflake/dbt data platform and a Power BI dashboard.

The business scenario is a marketing team that has customer, order, web-event, and paid-media data available, but the information is fragmented across sources and is not yet organized into a trusted decision-making layer.

The objective is not only to build a dashboard. The objective is to demonstrate the full delivery lifecycle:

```text
business problem
    ↓
stakeholder questions
    ↓
requirements definition
    ↓
data-source assessment
    ↓
metric definitions
    ↓
data modeling
    ↓
data quality + production controls
    ↓
semantic layer
    ↓
Power BI dashboard
    ↓
business validation
```

> This is a portfolio project using synthetic data. The "client" and stakeholder requirements below are a realistic business scenario created to drive the solution design.

## Business problem

The marketing team cannot reliably answer basic performance questions because data is distributed across customer, order, web-behavior, and advertising-spend datasets.

The main business issues are:

- paid-media spend and attributed revenue are not available in one trusted view;
- channel performance is difficult to compare consistently;
- there is no agreed attribution approach linking marketing touchpoints to orders;
- funnel conversion from session to add-to-cart to purchase is not centrally measured;
- customer acquisition quality cannot be evaluated using 90-day LTV and cohort behavior;
- KPI definitions such as ROAS, CAC, conversion rate, and LTV can be calculated differently by different analysts;
- the team needs a repeatable production process with tests, monitoring, lineage, and secure access rather than a one-off dashboard.

## Stakeholders

The solution is designed around three stakeholder groups.

### Marketing leadership

Needs a concise view of overall performance and the ability to answer:

- How much are we spending?
- How much revenue is attributed to marketing?
- What are ROAS and CAC?
- Which channels contribute the most revenue and new customers?
- How are those KPIs changing over time?

### Marketing / growth analysts

Need deeper analytical views for:

- channel-level attribution;
- attributed orders and revenue;
- funnel behavior and conversion;
- cohort and acquisition-channel LTV;
- filtering by channel and time period.

### Analytics / data engineering

Needs the solution to be:

- version controlled;
- testable;
- reproducible;
- separated into development and production;
- secure;
- observable;
- maintainable as event volume grows.

## Requirements gathered and defined

### BR-01 — Executive marketing performance

**Business need:** Marketing leadership needs a single summary of current performance.

**Required KPIs:**

- attributed revenue;
- attributed orders;
- total ad spend;
- new customers;
- ROAS;
- CAC.

**Required analysis:**

- compare revenue and spend by channel;
- view monthly revenue and ROAS trends;
- filter by channel and month.

**Delivered by:**

```text
dbt:      MART_CHANNEL_PERFORMANCE
Power BI: Executive Summary
```

### BR-02 — Marketing attribution

**Business need:** The team needs a documented and configurable method for assigning order revenue to marketing touchpoints.

**Requirements:**

- support first-touch attribution;
- support last-touch attribution;
- support linear attribution;
- use a configurable attribution window;
- keep attribution logic in the transformation layer rather than hard-coding it in BI;
- expose attributed revenue and attributed orders by channel.

**Implemented default:**

```text
Attribution model:  linear
Attribution window: 30 days
```

**Delivered by:**

```text
dbt:      INT_CUSTOMER_TOUCHPOINTS
          INT_ATTRIBUTED_REVENUE
          MART_CHANNEL_PERFORMANCE
Power BI: Marketing Attribution
```

### BR-03 — Funnel performance

**Business need:** Marketing analysts need to understand where engagement converts or drops off.

**Required funnel stages:**

```text
session
  ↓
add to cart
  ↓
purchase
```

**Required KPIs:**

- sessions;
- add-to-carts;
- purchases;
- add-to-cart rate;
- conversion rate.

**Required analysis:**

- compare funnel volumes by channel;
- compare conversion rate by channel;
- filter by channel and date.

**Delivered by:**

```text
dbt:      MART_FUNNEL
Power BI: Funnel Analysis
```

### BR-04 — Customer value and cohorts

**Business need:** Acquisition performance should not be judged only by immediate revenue. The business needs a view of customer value after acquisition.

**Requirements:**

- calculate customer revenue during the first 90 days after first non-refunded order;
- identify customers whose 90-day window is still accumulating;
- compare average 90-day LTV by acquisition channel;
- analyze LTV by customer cohort month.

**Delivered by:**

```text
dbt:      MART_CUSTOMER_LTV
Power BI: Customer LTV & Cohorts
```

### BR-05 — Consistent metric definitions

**Business need:** Business metrics must have one documented definition rather than being reimplemented differently in every report.

**Required governed metrics:**

- ad spend;
- attributed revenue;
- new customers;
- ROAS;
- CAC;
- sessions;
- purchases;
- conversion rate;
- average 90-day LTV.

**Delivered by:**

```text
dbt Semantic Layer / MetricFlow
models/marts/_marts.yml
models/marts/_time_spine.yml
```

The Power BI measures mirror these definitions where equivalent calculations are required in the local report.

### BR-06 — Data quality and trust

**Business need:** The dashboard should only be trusted if the data pipeline is tested.

**Requirements:**

- validate source freshness;
- validate uniqueness and non-null keys;
- validate accepted values and value ranges;
- reconcile modeled ad spend to source spend;
- fail production builds when critical quality checks fail.

**Delivered by:**

```text
dbt source freshness
schema tests
custom data tests
dbt build
GitHub Actions CI
dbt Cloud Production Build
```

### BR-07 — Customer history

**Business need:** Customer attributes may change over time and historical state must be preserved for future analysis.

**Requirement:** Keep slowly changing customer history.

**Delivered by:**

```text
dbt snapshot: SCD_CUSTOMERS
Snowflake:    NORTHWIND.SNAPSHOTS
```

### BR-08 — Scalable web-event processing

**Business need:** Web-event volume can grow much faster than customer or order tables.

**Requirements:**

- avoid rebuilding the full event history on every run;
- handle late-arriving events safely;
- prevent duplicated event records.

**Delivered by:**

```text
STG_WEB_EVENTS
materialization: incremental
strategy: merge
unique key: event_id
lookback: 3 days
```

### BR-09 — Production monitoring

**Business need:** The data platform should provide operational visibility, not only business reporting.

**Requirements:**

- monitor Snowflake warehouse usage;
- identify expensive / long-running queries;
- detect unusual movements in spend, attributed revenue, and conversion rate;
- provide warning-level anomaly checks without unnecessarily blocking the production pipeline.

**Delivered by:**

```text
PROD_MONITORING
MON_WAREHOUSE_DAILY_USAGE
MON_QUERY_PERFORMANCE
MON_MARKETING_DAILY_METRICS
MON_MARKETING_ANOMALIES
```

### BR-10 — Secure and production-style deployment

**Business need:** The solution must demonstrate a controlled path from development to production.

**Requirements:**

- use a dedicated Snowflake transformation role;
- use RSA key-pair authentication;
- keep credentials and private keys out of Git;
- isolate development from production schemas;
- validate pull requests before merge;
- run a scheduled production dbt job;
- document failure/freshness alerting.

**Delivered by:**

```text
Snowflake TRANSFORMER role
RSA key-pair authentication
GitHub feature branch → PR → CI → main
dbt Cloud Production environment
daily Production Build
production alerting workflow
```

## Requirement-to-deliverable traceability

| Requirement | Primary dbt / platform implementation | Business output |
|---|---|---|
| BR-01 Executive performance | `MART_CHANNEL_PERFORMANCE` | Executive Summary |
| BR-02 Attribution | `INT_CUSTOMER_TOUCHPOINTS`, `INT_ATTRIBUTED_REVENUE`, `MART_CHANNEL_PERFORMANCE` | Marketing Attribution |
| BR-03 Funnel | `MART_FUNNEL` | Funnel Analysis |
| BR-04 LTV & cohorts | `MART_CUSTOMER_LTV` | Customer LTV & Cohorts |
| BR-05 Metric consistency | dbt Semantic Layer / MetricFlow | Shared metric definitions |
| BR-06 Data quality | dbt tests, freshness, CI/CD | Trusted production data |
| BR-07 Customer history | `SCD_CUSTOMERS` snapshot | Historical customer state |
| BR-08 Scalable events | incremental `STG_WEB_EVENTS` | Efficient event processing |
| BR-09 Monitoring | `PROD_MONITORING` models + anomaly tests | Operational visibility |
| BR-10 Secure deployment | Snowflake roles, key pair, GitHub CI, dbt Cloud | Controlled production workflow |

## Acceptance criteria

The project is considered complete when:

1. the five raw source datasets are available in Snowflake;
2. dbt builds staging, intermediate, mart, monitoring, snapshot, and Semantic Layer resources successfully;
3. critical dbt tests pass and source freshness is evaluated;
4. marketing attribution is configurable and the production configuration is documented;
5. the core business metrics are available from the marts and Semantic Layer;
6. the four Power BI pages answer the stakeholder questions above;
7. channel and date filters work on the relevant dashboard pages;
8. the dashboard KPIs reconcile to the production marts;
9. GitHub CI passes before code is merged;
10. the dbt Cloud Production Build successfully deploys `main` to Snowflake.

## Scope decisions

### In scope

- synthetic customer, order, event, and ad-spend data;
- Snowflake warehouse and production schemas;
- dbt transformations, tests, snapshots, documentation, and metrics;
- configurable marketing attribution;
- 90-day LTV;
- funnel analytics;
- cost/query monitoring;
- anomaly detection;
- Power BI Desktop reporting;
- GitHub CI and dbt Cloud production deployment;
- optional Airflow orchestration example.

### Out of scope

The following would be realistic next phases but are not required for this portfolio delivery:

- live Google Ads / Meta Ads API ingestion;
- real-time or streaming analytics;
- predictive marketing models;
- production Power BI Service deployment and workspace governance;
- production deployment of the optional Airflow DAG.

## End-to-end delivery story

This project is deliberately organized to show that analytics work starts before SQL and ends after the dashboard.

```text
1. Understand the business problem
2. Identify stakeholders and decision questions
3. Translate questions into measurable requirements
4. Identify the source data needed to answer them
5. Define KPI and attribution logic
6. Design Snowflake/dbt models at explicit grains
7. Add tests, snapshots, incremental processing, monitoring, and security
8. Govern metrics in the Semantic Layer
9. Build the Power BI reporting experience
10. Validate the output against the agreed requirements
11. Deploy changes through CI/CD
```

The final dashboard is therefore the presentation layer of a requirements-driven analytics solution rather than a standalone visualization exercise.
