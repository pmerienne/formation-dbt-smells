with source as (

    select * from {{ source('megashop', 'customers') }}

),

renamed as (

    select
        cast(customer_id as integer) as customer_id,
        {{ capitalize_first_letter('first_name') }} as first_name,
        {{ capitalize_first_letter('last_name') }} as last_name,
        cast(signup_date as date) as signup_date,
        email
    from source
    where email is not null

)

select * from renamed
