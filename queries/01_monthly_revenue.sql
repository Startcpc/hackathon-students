WITH months AS (
    SELECT generate_series(
        DATE '2016-09-01',
        DATE '2018-08-01',
        INTERVAL '1 month'
    )::date AS month_start
)

SELECT
    TO_CHAR(m.month_start, 'YYYY-MM') AS month,

    COUNT(o.order_id) AS order_count,

    COALESCE(
        SUM(
            CASE
                WHEN o.order_status = 'delivered'
                THEN o.product_revenue
                ELSE 0
            END
        ),
        0
    )::numeric(14, 2) AS revenue

FROM months m

LEFT JOIN core.v_orders o
    ON o.purchased_at >= m.month_start
   AND o.purchased_at < m.month_start + INTERVAL '1 month'

GROUP BY m.month_start
ORDER BY m.month_start;