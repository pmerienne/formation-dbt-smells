with orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

joined as (

    select
        o.order_id,
        o.customer_id,
        lower(trim(c.email)) as customer_email,
        upper(trim(c.first_name)) as customer_first_name,
        upper(trim(c.last_name)) as customer_last_name,
        o.order_date,
        case
            when upper(trim(p.category)) in ('ELECTRONIC','ELECTRONICS','ELEC') then 'ELECTRONICS'
            when upper(trim(p.category)) in ('CLOTH','CLOTHING','CLOTHES') then 'CLOTHING'
            when upper(trim(p.category)) in ('BOOK','BOOKS') then 'BOOKS'
            else upper(trim(p.category))
        end as category,
        o.quantity,
        o.total_amount
    from orders o
    left join products p on o.product_id = p.product_id
    left join customers c on o.customer_id = c.customer_id

),

aggregated as (

    select
        date_trunc('month', order_date) as order_month,
        category as category,
        count(distinct order_id) as nb_orders,
        sum(quantity) as total_quantity,
        sum(total_amount) as total_revenue
    from joined
    group by 1, 2
)

select * from aggregated
