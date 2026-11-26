# Task 2 query results

Executed on SQLite 3.53.1 using the packaged Task 1 data.

## Loaded rows

| table | rows |
| --- | --- |
| customers | 12 |
| products | 4 |
| transactions | 749 |

## 1. Total sales by region and category

| region | category | total_sales_usd |
| --- | --- | --- |
| East | Accessories | 13395.25 |
| East | Electronics | 294297.00 |
| North | Accessories | 8722.65 |
| North | Electronics | 293447.00 |
| North | Furniture | 66641.40 |
| South | Accessories | 13485.24 |
| South | Furniture | 65961.00 |
| West | Accessories | 4912.14 |
| West | Electronics | 291847.02 |
| West | Furniture | 66112.20 |

## 2. Top 5 products by total revenue

| product_id | product_name | total_revenue_usd |
| --- | --- | --- |
| P01 | Laptop | 879591.02 |
| P05 | Desk | 198714.60 |
| P04 | Keyboard | 26432.40 |
| P02 | Mouse | 14082.88 |

## 3. Monthly sales trend

| sale_month | total_sales_usd |
| --- | --- |
| 2022-12 | 756.00 |
| 2023-01 | 59993.84 |
| 2023-02 | 59881.91 |
| 2023-03 | 64577.97 |
| 2023-04 | 60231.28 |
| 2023-05 | 68304.48 |
| 2023-06 | 63728.71 |
| 2023-07 | 67005.92 |
| 2023-08 | 64463.39 |
| 2023-09 | 59968.31 |
| 2023-10 | 67836.40 |
| 2023-11 | 64103.11 |
| 2023-12 | 66615.63 |
| 2024-01 | 64243.79 |
| 2024-02 | 59919.89 |
| 2024-03 | 66553.75 |
| 2024-04 | 61542.02 |
| 2024-05 | 63619.36 |
| 2024-06 | 35475.14 |

## 4. Average discount percentage per region

| region | average_discount_pct |
| --- | --- |
| East | 5.99 |
| North | 6.01 |
| South | 5.96 |
| West | 6.02 |

## 5. Transactions with total value over $1,000

| transactions_over_1000 |
| --- |
| 281 |

## Query plans before and after indexing

| Query | Before indexes | After indexes |
| --- | --- | --- |
| Amount threshold | SCAN transactions | SEARCH transactions USING INDEX idx_transactions_total_value (total_value_cents>?) |
| Monthly aggregation | SCAN transactions · USE TEMP B-TREE FOR GROUP BY | SCAN transactions USING INDEX idx_transactions_month_value |
| Product lookup | SCAN transactions | SEARCH transactions USING INDEX idx_transactions_product (product_id=?) |
| Customer lookup | SCAN transactions | SEARCH transactions USING INDEX idx_transactions_customer (customer_id=?) |

