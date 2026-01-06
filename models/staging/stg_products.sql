with source as (

    select * from {{ source('megashop', 'products') }}

),

renamed as (

    select
        cast(product_id as integer) as product_id,
        name,
        category,
        cast(price as float) as price
    from source

)

select * from renamed
