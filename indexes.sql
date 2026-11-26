-- Child foreign-key indexes support joins and parent-key checks.
CREATE INDEX IF NOT EXISTS idx_transactions_customer ON transactions (customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_product ON transactions (product_id);

-- Matches the month expression and covers the monthly revenue query.
CREATE INDEX IF NOT EXISTS idx_transactions_month_value
    ON transactions (sale_month, total_value_cents);

-- Supports the strict > $1,000 range count and other amount thresholds.
CREATE INDEX IF NOT EXISTS idx_transactions_total_value
    ON transactions (total_value_cents);
