-- 1. Order Volume and Revenue by Order Status
SELECT 
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(CAST(oi.price AS REAL)), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY total_revenue DESC;

-- 2. Monthly Delivered Order Volume and Revenue Trend
SELECT 
    SUBSTR(o.order_purchase_timestamp, 1, 7) AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(CAST(oi.price AS REAL)), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month ASC;

-- 3. Delivery Performance vs. Customer Satisfaction
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late' 
        ELSE 'On-Time' 
    END AS delivery_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(CAST(r.review_score AS REAL)), 2) AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date != ''
  AND o.order_estimated_delivery_date != ''
GROUP BY delivery_status;

-- 4. Top 10 Product Categories by Delivered Revenue
SELECT 
    COALESCE(NULLIF(ct.product_category_name_english, ''), 'uncategorized') AS category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(CAST(oi.price AS REAL)), 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

-- 5. Customer Retention & Repeat Purchase Rate (CTE)
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;