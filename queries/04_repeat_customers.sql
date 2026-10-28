WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS orders_count
    FROM core.v_orders
    WHERE customer_unique_id IS NOT NULL
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE orders_count > 1
    ) AS returning_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE orders_count > 1
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS returning_share_pct

FROM customer_orders;