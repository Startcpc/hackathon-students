SELECT
    ROUND(AVG(order_total), 2) AS average_check,
    ROUND(AVG(item_lines), 2) AS average_lines_per_order,
    ROUND(AVG(item_lines), 2) AS average_units_per_order
FROM core.v_orders
WHERE order_status = 'delivered';