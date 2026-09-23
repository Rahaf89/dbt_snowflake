{% snapshot scd_customers %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='check',
        check_cols=['acquisition_channel'],
    )
}}

select * from {{ ref('stg_customers') }}

{% endsnapshot %}
