/*
Olist E-commerce Delivery Performance Analysis
Database: project_d
Table: public.olist_orders

Prerequisite:
- Connect to project_d in PostgreSQL.
- Create and load public.olist_orders before running these analysis queries.
- This script only reads data; it does not create, alter, or delete database objects.
*/

-- 1. Check total number of orders
SELECT COUNT(*) AS total_orders
FROM public.olist_orders;


-- 2. Order status distribution
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM public.olist_orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 3. Average delivery time in days for delivered orders
SELECT
    COUNT(*) AS delivered_orders_with_delivery_date,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date - order_purchase_timestamp
                )
            ) / 86400
        )::numeric,
        2
    ) AS avg_delivery_days
FROM public.olist_orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;


-- 4. Overall late-delivery rate among delivered orders with both dates available
SELECT
    COUNT(*) AS eligible_delivered_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct
FROM public.olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- 5. Monthly delivery performance by purchase month
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS purchase_month,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_rate_pct
FROM public.olist_orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY purchase_month;


-- 6. Five months with the highest late-delivery rate
-- Excludes months with fewer than 100 eligible delivered orders to avoid
-- misleading rankings caused by very small monthly counts.
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS purchase_month,
    COUNT(*) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_rate_pct
FROM public.olist_orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
HAVING COUNT(*) >= 100
ORDER BY late_rate_pct DESC
LIMIT 5;
