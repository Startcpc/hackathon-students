BEGIN;

-- Удаляем предыдущую версию нашей модели, если она есть.
-- Схему raw не трогаем.
DROP TABLE IF EXISTS
    core.order_reviews,
    core.order_payments,
    core.order_items,
    core.orders,
    core.products,
    core.sellers,
    core.customers,
    core.product_category_translation
CASCADE;


-- 1. Покупатели.
-- customer_id относится к конкретной записи покупателя.
-- customer_unique_id помогает определять одного человека
-- при повторных заказах.

CREATE TABLE core.customers AS
SELECT
    NULLIF(BTRIM(customer_id), '') AS customer_id,
    NULLIF(BTRIM(customer_unique_id), '') AS customer_unique_id,
    NULLIF(BTRIM(customer_zip_code_prefix), '') AS zip_code_prefix,
    NULLIF(BTRIM(customer_city), '') AS city,
    NULLIF(BTRIM(customer_state), '') AS state
FROM raw.customers;

ALTER TABLE core.customers
    ADD PRIMARY KEY (customer_id);


-- 2. Продавцы.

CREATE TABLE core.sellers AS
SELECT
    NULLIF(BTRIM(seller_id), '') AS seller_id,
    NULLIF(BTRIM(seller_zip_code_prefix), '') AS zip_code_prefix,
    NULLIF(BTRIM(seller_city), '') AS city,
    NULLIF(BTRIM(seller_state), '') AS state
FROM raw.sellers;

ALTER TABLE core.sellers
    ADD PRIMARY KEY (seller_id);


-- 3. Товары.
-- Исправляем опечатку lenght в названиях полей модели.

CREATE TABLE core.products AS
SELECT
    NULLIF(BTRIM(product_id), '') AS product_id,
    NULLIF(BTRIM(product_category_name), '') AS category_name,
    NULLIF(BTRIM(product_name_lenght), '')::numeric
        AS product_name_length,
    NULLIF(BTRIM(product_description_lenght), '')::numeric
        AS product_description_length,
    NULLIF(BTRIM(product_photos_qty), '')::numeric
        AS photos_qty,
    NULLIF(BTRIM(product_weight_g), '')::numeric
        AS weight_g,
    NULLIF(BTRIM(product_length_cm), '')::numeric
        AS length_cm,
    NULLIF(BTRIM(product_height_cm), '')::numeric
        AS height_cm,
    NULLIF(BTRIM(product_width_cm), '')::numeric
        AS width_cm
FROM raw.products;

ALTER TABLE core.products
    ADD PRIMARY KEY (product_id);


-- 4. Перевод названий категорий.

CREATE TABLE core.product_category_translation AS
SELECT
    NULLIF(BTRIM(product_category_name), '') AS category_name,
    NULLIF(BTRIM(product_category_name_english), '') AS category_name_english
FROM raw.product_category_translation;

ALTER TABLE core.product_category_translation
    ADD PRIMARY KEY (category_name);


-- 5. Заказы.
-- Одна строка модели = один заказ.

CREATE TABLE core.orders AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(customer_id), '') AS customer_id,
    NULLIF(BTRIM(order_status), '') AS order_status,
    NULLIF(BTRIM(order_purchase_timestamp), '')::timestamp
        AS purchased_at,
    NULLIF(BTRIM(order_approved_at), '')::timestamp
        AS approved_at,
    NULLIF(BTRIM(order_delivered_carrier_date), '')::timestamp
        AS delivered_to_carrier_at,
    NULLIF(BTRIM(order_delivered_customer_date), '')::timestamp
        AS delivered_to_customer_at,
    NULLIF(BTRIM(order_estimated_delivery_date), '')::timestamp
        AS estimated_delivery_at
FROM raw.orders;

ALTER TABLE core.orders
    ADD PRIMARY KEY (order_id);


-- 6. Товарные позиции заказов.
-- Одна строка = одна позиция внутри конкретного заказа.
-- Цена товара и доставка хранятся раздельно.

CREATE TABLE core.order_items AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(order_item_id), '')::integer AS order_item_id,
    NULLIF(BTRIM(product_id), '') AS product_id,
    NULLIF(BTRIM(seller_id), '') AS seller_id,
    NULLIF(BTRIM(shipping_limit_date), '')::timestamp
        AS shipping_limit_at,
    NULLIF(BTRIM(price), '')::numeric(14, 2) AS price,
    NULLIF(BTRIM(freight_value), '')::numeric(14, 2) AS freight_value
FROM raw.order_items;

ALTER TABLE core.order_items
    ADD PRIMARY KEY (order_id, order_item_id);


-- 7. Платежи.
-- У одного заказа может быть несколько записей о платежах.

CREATE TABLE core.order_payments AS
SELECT
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(payment_sequential), '')::integer
        AS payment_sequential,
    NULLIF(BTRIM(payment_type), '') AS payment_type,
    NULLIF(BTRIM(payment_installments), '')::integer
        AS payment_installments,
    NULLIF(BTRIM(payment_value), '')::numeric(14, 2)
        AS payment_value
FROM raw.order_payments;

ALTER TABLE core.order_payments
    ADD PRIMARY KEY (order_id, payment_sequential);


-- 8. Отзывы.
-- review_id в исходных данных не всегда уникален.
-- Поэтому используем комбинацию review_id и order_id.

CREATE TABLE core.order_reviews AS
SELECT
    NULLIF(BTRIM(review_id), '') AS review_id,
    NULLIF(BTRIM(order_id), '') AS order_id,
    NULLIF(BTRIM(review_score), '')::integer AS review_score,
    NULLIF(BTRIM(review_comment_title), '') AS comment_title,
    NULLIF(BTRIM(review_comment_message), '') AS comment_message,
    NULLIF(BTRIM(review_creation_date), '')::timestamp
        AS created_at,
    NULLIF(BTRIM(review_answer_timestamp), '')::timestamp
        AS answered_at
FROM raw.order_reviews;

ALTER TABLE core.order_reviews
    ADD PRIMARY KEY (review_id, order_id);

-- Закрепляем связи между таблицами модели.

ALTER TABLE core.orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES core.customers (customer_id);

ALTER TABLE core.order_items
    ADD CONSTRAINT fk_items_order
    FOREIGN KEY (order_id)
    REFERENCES core.orders (order_id);

ALTER TABLE core.order_items
    ADD CONSTRAINT fk_items_product
    FOREIGN KEY (product_id)
    REFERENCES core.products (product_id);

ALTER TABLE core.order_items
    ADD CONSTRAINT fk_items_seller
    FOREIGN KEY (seller_id)
    REFERENCES core.sellers (seller_id);

ALTER TABLE core.order_payments
    ADD CONSTRAINT fk_payments_order
    FOREIGN KEY (order_id)
    REFERENCES core.orders (order_id);

ALTER TABLE core.order_reviews
    ADD CONSTRAINT fk_reviews_order
    FOREIGN KEY (order_id)
    REFERENCES core.orders (order_id);
-- Индексы ускоряют соединение таблиц по соответствующим полям.

CREATE INDEX idx_orders_customer
    ON core.orders (customer_id);

CREATE INDEX idx_items_product
    ON core.order_items (product_id);

CREATE INDEX idx_items_seller
    ON core.order_items (seller_id);

CREATE INDEX idx_products_category
    ON core.products (category_name);

CREATE INDEX idx_reviews_order
    ON core.order_reviews (order_id);


-- Кратко фиксируем гранулярность основных таблиц.

COMMENT ON TABLE core.orders IS
    'Одна строка на заказ';

COMMENT ON TABLE core.order_items IS
    'Одна строка на товарную позицию заказа';

COMMENT ON TABLE core.order_payments IS
    'Одна строка на запись о платеже';

COMMENT ON TABLE core.order_reviews IS
    'Одна строка на пару review_id и order_id';

COMMENT ON TABLE core.customers IS
    'Записи покупателей с customer_id и customer_unique_id';

-- Общая основа для аналитики.
-- Одна строка = одна товарная позиция заказа.

CREATE OR REPLACE VIEW core.v_order_items AS
SELECT
    i.order_id,
    i.order_item_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_status,
    o.purchased_at,
    o.delivered_to_customer_at,
    i.product_id,
    COALESCE(
        t.category_name_english,
        p.category_name,
        'unknown'
    ) AS category_name,
    i.seller_id,
    s.city AS seller_city,
    s.state AS seller_state,
    i.price,
    i.freight_value,
    i.price + i.freight_value AS item_total_value
FROM core.order_items i
JOIN core.orders o
    ON o.order_id = i.order_id
JOIN core.customers c
    ON c.customer_id = o.customer_id
JOIN core.products p
    ON p.product_id = i.product_id
JOIN core.sellers s
    ON s.seller_id = i.seller_id
LEFT JOIN core.product_category_translation t
    ON t.category_name = p.category_name;
-- Одна строка на заказ.
-- Суммируем товарные позиции и стоимость доставки.

CREATE OR REPLACE VIEW core.v_orders AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_status,
    o.purchased_at,
    o.delivered_to_customer_at,

    COUNT(i.order_item_id) AS item_lines,

    COUNT(DISTINCT i.product_id) AS distinct_products,

    COALESCE(SUM(i.price), 0)::numeric(14, 2)
        AS product_revenue,

    COALESCE(SUM(i.freight_value), 0)::numeric(14, 2)
        AS freight_total,

    COALESCE(SUM(i.price + i.freight_value), 0)::numeric(14, 2)
        AS order_total

FROM core.orders o
LEFT JOIN core.customers c
    ON c.customer_id = o.customer_id
LEFT JOIN core.order_items i
    ON i.order_id = o.order_id

GROUP BY
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_status,
    o.purchased_at,
    o.delivered_to_customer_at;
COMMIT;


-- Показываем, сколько строк попало в каждую таблицу модели.

SELECT 'customers' AS table_name, COUNT(*) AS rows_count
FROM core.customers
UNION ALL
SELECT 'sellers', COUNT(*) FROM core.sellers
UNION ALL
SELECT 'products', COUNT(*) FROM core.products
UNION ALL
SELECT 'product_category_translation', COUNT(*)
FROM core.product_category_translation
UNION ALL
SELECT 'orders', COUNT(*) FROM core.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM core.order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM core.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM core.order_reviews
ORDER BY table_name;