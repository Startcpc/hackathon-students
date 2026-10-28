SELECT
    seller_id AS seller,
    seller_city AS city,
    seller_state AS state,
    COUNT(DISTINCT order_id) AS orders_count,
    COUNT(*) AS units_sold,
    ROUND(SUM(price), 2) AS revenue
FROM core.v_order_items
WHERE order_status = 'delivered'
GROUP BY
    seller_id,
    seller_city,
    seller_state
ORDER BY revenue DESC
LIMIT 10;