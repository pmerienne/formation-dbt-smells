with orders as (

    select * from {{ ref('stg_orders') }}

),

final as (

    select
        order_id,
        customer_id,
        product_id,
        order_date,
        quantity,
        total_amount
    from orders

)

select * from final
