# Task 2 · Database design and querying

This project models the accepted Task 1 sales in a normalized SQLite database and answers five analytical questions. The packaged CSVs contain 749 transactions, 4 products, and 12 customers. They were exported from the final Task 1 database after the incremental load and replay. Rejected records and duplicate arrivals are excluded. The original Task 1 database can remain separate.

## Run the demo

Open PowerShell in the extracted `sales-database-task2` folder. Run with **Python 3.11+** and **SQLite 3.37+**. Python's standard library supplies the SQLite driver. No additional packages are required.

```powershell
python run_demo.py
```

The command creates an in-memory database, loads the CSVs, executes all five queries, and prints a report with the query plans. [sample_outputs.md](sample_outputs.md) shows a verified run.

To create a database file you can reopen and query in a SQLite client, run the command with a new filename.

```powershell
python run_demo.py --database task2.db
```

If you prefer to launch it from Jupyter, open a notebook in the extracted project folder and run `%run run_demo.py --database task2.db` in a cell. To rerun the same demo, omit `--database` or supply a different file name.

To execute the SQL manually, open a fresh SQLite database and run [schema.sql](schema.sql). Import the CSVs into their matching tables in customer → product → transaction order, using the CSV headers as column names and excluding the generated columns from the insert. Then apply [indexes.sql](indexes.sql) and run [queries.sql](queries.sql). Keep foreign keys enabled on any connection that imports or changes data.

## Schema

| Table | Grain | Primary key | Relationships |
| --- | --- | --- | --- |
| `customers` | One row per customer | `customer_id` | One customer can have many transactions. |
| `products` | One row per product with its name and category | `product_id` | One product can appear in many transactions. |
| `transactions` | One source transaction with one product | `transaction_id` | `customer_id` and `product_id` are required foreign keys. |

Product names and categories are stored once per product. Customers have only an ID because the source has no other customer attributes. The transaction holds the quantity, historical unit price, discount, sale region, and timestamp. Region describes where the sale occurred, which can differ across transactions from the same customer.

Two virtual generated columns expose the UTC month and net total. SQLite computes them from the transaction values, so they cannot drift when the source columns are updated. Money is represented in integer cents and discounts in basis points. The schema bounds unit price at 100,000,000 cents and quantity at 1,000,000 to keep the multiplication within SQLite's signed 64-bit integer range.

## Query definitions

| Query | Business rule |
| --- | --- |
| Total sales by region and category | Join transactions to products and sum net sales for each observed region and category combination. |
| Top five products by revenue | Sum net sales per product and sort highest first, using product ID to break ties. The sample has four products with valid sales, so four rows are returned. |
| Monthly sales trend | Sum net sales by UTC calendar month and sort chronologically. The report includes months with recorded sales. |
| Average discount percentage per region | Take the ordinary mean across transactions. Each transaction counts once, including those with zero discount. Task 1 mapped missing discounts to zero. |
| Transactions over $1,000 | Count net transaction totals strictly greater than 100,000 cents. A total of exactly $1,000 is excluded. |

Throughout the reports, sales and revenue mean net sales after discounts, and the assignment's dollar values are treated as USD. For each transaction, SQLite multiplies unit price by quantity, applies the percentage discount, and rounds half up to the nearest cent. The reports aggregate those cents and convert the result to dollars.

## Indexes and observed performance impact

The demo runs `EXPLAIN QUERY PLAN` before and after applying [indexes.sql](indexes.sql), with `ANALYZE` in both cases. The plans below describe how SQLite accessed this sample. They do not measure elapsed time. The primary keys already have their own indexes. [SQLite foreign keys](https://www.sqlite.org/foreignkeys.html) · [SQLite EXPLAIN QUERY PLAN](https://www.sqlite.org/eqp.html)

| Index | What it supports | What changed in the sample plan |
| --- | --- | --- |
| `idx_transactions_customer` | Lookups by customer and finding child rows when a customer key is updated or deleted | A full transaction scan became an indexed lookup for one customer. |
| `idx_transactions_product` | Lookups and joins by product and finding child rows when a product key is updated or deleted | A full transaction scan became an indexed lookup for one product. |
| `idx_transactions_month_value` | Monthly revenue aggregation | SQLite scanned the index in month order and dropped the temporary B-tree previously used for grouping. The query still reads all monthly entries. |
| `idx_transactions_total_value` | Transaction amount thresholds | A full transaction scan became an index range search for values above 100,000 cents. |

The broad region and category reports still aggregate a large share of the fact rows. Indexes use storage and add maintenance work to inserts and updates, so this project adds indexes for the access patterns shown above. The full plans are in [sample_outputs.md](sample_outputs.md), and the statements to reproduce them are in [index_plans.sql](index_plans.sql).
