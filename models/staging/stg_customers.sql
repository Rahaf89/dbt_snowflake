with source as (
    select * from {{ source('raw', 'customers') }}
),

cleaned as (
    select
        customer_id,
        lower(trim(email))          as email,
        cast(signup_date as date)   as signup_date,
        acquisition_channel
    from source
    where customer_id is not null
)

select * from cleaned
