PRAGMA foreign_keys = ON;

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY NOT NULL CHECK (length(trim(customer_id)) > 0)
) STRICT;

CREATE TABLE products (
    product_id   TEXT PRIMARY KEY NOT NULL CHECK (length(trim(product_id)) > 0),
    product_name TEXT NOT NULL CHECK (length(trim(product_name)) > 0),
    category     TEXT NOT NULL CHECK (length(trim(category)) > 0)
) STRICT;

-- Grain: one transaction with one product, matching the source.
-- Unit price, discount and region describe the sale at the time it occurred.
CREATE TABLE transactions (
    transaction_id   TEXT PRIMARY KEY NOT NULL CHECK (length(trim(transaction_id)) > 0),
    customer_id      TEXT NOT NULL REFERENCES customers (customer_id),
    product_id       TEXT NOT NULL REFERENCES products (product_id),
    transaction_at   TEXT NOT NULL CHECK (
        transaction_at GLOB '????-??-??T??:??:??.??????Z'
        AND julianday(transaction_at) IS NOT NULL
    ),
    region           TEXT NOT NULL CHECK (length(trim(region)) > 0),
    quantity         INTEGER NOT NULL CHECK (quantity BETWEEN 1 AND 1000000),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents BETWEEN 0 AND 100000000),
    discount_bps     INTEGER NOT NULL DEFAULT 0 CHECK (discount_bps BETWEEN 0 AND 10000),

    sale_month TEXT GENERATED ALWAYS AS (substr(transaction_at, 1, 7)) VIRTUAL,

    -- All operands are integers. Add half the divisor to round half up to cents.
    total_value_cents INTEGER GENERATED ALWAYS AS (
        (unit_price_cents * quantity * (10000 - discount_bps) + 5000) / 10000
    ) VIRTUAL
) STRICT;
