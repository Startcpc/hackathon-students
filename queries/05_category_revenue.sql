WITH category_revenue AS (
    SELECT
        category_name,
        SUM(price) AS revenue
    FROM core.v_order_items
    WHERE order_status = 'delivered'
    GROUP BY category_name
),
total_revenue AS (
    SELECT SUM(revenue) AS total
    FROM category_revenue
)

SELECT
    cr.category_name AS category,
    ROUND(cr.revenue, 2) AS revenue,
    ROUND(
        100.0 * cr.revenue / NULLIF(tr.total, 0),
        2
    ) AS revenue_share_pct
FROM category_revenue cr
CROSS JOIN total_revenue tr
ORDER BY cr.revenue DESC;