with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

first_orders as (
    select
        customer_id,
        min(order_date) as first_order_date,
        count(order_id) as total_orders,
        sum(total_amount) as total_spent
    from orders
    group by customer_id
),

order_intervals as (
    select
        customer_id,
        datediff(
            'day',
            order_date,
            lead(order_date) over (partition by customer_id order by order_date)
        ) as days_between_orders
    from orders
),

avg_days_between_orders as (
    select
        customer_id,
        avg(days_between_orders) as avg_days_between_orders
    from order_intervals
    where days_between_orders is not null
    group by customer_id
)

select
    c.customer_id,
    lower(trim(c.email)) as email,
    upper(trim(c.first_name)) as first_name,
    upper(trim(c.last_name)) as last_name,
    c.signup_date,
    f.first_order_date,
    f.total_orders,
    f.total_spent,
    a.avg_days_between_orders as avg_days_between_orders
from customers c
inner join first_orders f on c.customer_id = f.customer_id
inner join avg_days_between_orders a on c.customer_id = a.customer_id
