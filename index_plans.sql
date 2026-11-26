-- Run each statement before and after applying indexes.sql to compare plans.

-- 1. Amount threshold
EXPLAIN QUERY PLAN
SELECT COUNT(*)
FROM transactions
WHERE total_value_cents > 100000;

-- 2. Full monthly revenue aggregation
EXPLAIN QUERY PLAN
SELECT sale_month, SUM(total_value_cents)
FROM transactions
GROUP BY sale_month
ORDER BY sale_month;

-- 3. Product ID lookup, also representative of a foreign-key child lookup
EXPLAIN QUERY PLAN
SELECT transaction_id FROM transactions WHERE product_id = 'P01';

-- 4. Customer ID lookup, also representative of a foreign-key child lookup
EXPLAIN QUERY PLAN
SELECT transaction_id FROM transactions WHERE customer_id = 'C001';
