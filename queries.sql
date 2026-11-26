-- 1. Total sales by region and category
SELECT
    t.region,
    p.category,
    ROUND(SUM(t.total_value_cents) / 100.0, 2) AS total_sales_usd
FROM transactions AS t
JOIN products AS p ON p.product_id = t.product_id
GROUP BY t.region, p.category
ORDER BY t.region, p.category;

-- 2. Top 5 products by total revenue
SELECT
    p.product_id,
    p.product_name,
    ROUND(SUM(t.total_value_cents) / 100.0, 2) AS total_revenue_usd
FROM products AS p
JOIN transactions AS t ON t.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY SUM(t.total_value_cents) DESC, p.product_id
LIMIT 5;

-- 3. Monthly sales trend (UTC calendar month)
SELECT
    sale_month,
    ROUND(SUM(total_value_cents) / 100.0, 2) AS total_sales_usd
FROM transactions
GROUP BY sale_month
ORDER BY sale_month;

-- 4. Average discount percentage per region (one vote per transaction)
SELECT
    region,
    ROUND(AVG(discount_bps) / 100.0, 2) AS average_discount_pct
FROM transactions
GROUP BY region
ORDER BY region;

-- 5. Number of transactions with total_value > $1,000
SELECT COUNT(*) AS transactions_over_1000
FROM transactions
WHERE total_value_cents > 100000;
