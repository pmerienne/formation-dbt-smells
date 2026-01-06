WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

orders_data AS (
    SELECT
        o.order_id,
        o.order_date,
        o.customer_id,
        lower(trim(c.email)) as customer_email,
        o.product_id,
        case
            when upper(trim(p.category)) in ('ELECTRONIC','ELECTRONICS','ELEC') then 'ELECTRONICS'
            when upper(trim(p.category)) in ('CLOTH','CLOTHING','CLOTHES') then 'CLOTHING'
            when upper(trim(p.category)) in ('BOOK','BOOKS') then 'BOOKS'
            else upper(trim(p.category))
        end as category,
        o.quantity,
        o.total_amount AS total_revenue
    FROM {{ ref('stg_orders') }} o
    JOIN {{ ref('stg_products') }} p ON o.product_id = p.product_id
    LEFT JOIN customers c ON o.customer_id = c.customer_id
),

aggregated_orders AS (
    SELECT
        category,
        DATE_TRUNC('month', order_date) AS order_month,
        SUM(total_revenue) AS total_revenue,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM orders_data
    GROUP BY category, DATE_TRUNC('month', order_date)
),

orders_trends AS (
    SELECT
        category,
        order_month,
        total_revenue,
        total_quantity,
        LAG(total_revenue) OVER (PARTITION BY category ORDER BY order_month) AS previous_month_revenue,
        LAG(total_quantity) OVER (PARTITION BY category ORDER BY order_month) AS previous_month_quantity
    FROM aggregated_orders
),

final AS (
    SELECT
        st.category,
        st.order_month,
        st.total_revenue,
        st.total_quantity,
        st.previous_month_revenue,
        ag.unique_customers
    FROM orders_trends st
    JOIN aggregated_orders ag
    ON st.category = ag.category
    AND st.order_month = ag.order_month
)

SELECT * FROM final