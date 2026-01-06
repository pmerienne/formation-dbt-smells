with source as (

    select * from {{ source('megashop', 'orders') }}

),

renamed as (

    select
        cast(order_id as integer) as order_id,
        cast(customer_id as integer) as customer_id,
        cast(product_id as integer) as product_id,
        cast(order_date as date) as order_date,
        cast(quantity as integer) as quantity,
        cast(total_amount as float) as total_amount
    from source

)

select * from renamed
