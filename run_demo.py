"""Build the SQLite demo, run the five queries, and print a Markdown report."""

import argparse
import csv
import sqlite3
from contextlib import closing
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TABLES = {
    "customers": ("customer_id",),
    "products": ("product_id", "product_name", "category"),
    "transactions": (
        "transaction_id", "customer_id", "product_id", "transaction_at", "region",
        "quantity", "unit_price_cents", "discount_bps",
    ),
}
REPORT_TITLES = (
    "Total sales by region and category",
    "Top 5 products by total revenue",
    "Monthly sales trend",
    "Average discount percentage per region",
    "Transactions with total value over $1,000",
)
PLAN_LABELS = ("Amount threshold", "Monthly aggregation", "Product lookup", "Customer lookup")


def load_data(connection):
    # Load parent tables first so foreign-key checks stay enabled.
    with connection:
        for table, columns in TABLES.items():
            with (ROOT / "data" / f"{table}.csv").open(encoding="utf-8", newline="") as source:
                rows = csv.DictReader(source)
                if tuple(rows.fieldnames or ()) != columns:
                    raise ValueError(f"Unexpected columns in {table}.csv")
                placeholders = ", ".join("?" for _ in columns)
                connection.executemany(
                    f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})",
                    (tuple(row[column] for column in columns) for row in rows),
                )


def statements(filename):
    # Use SQLite's statement boundary check so quoted semicolons are handled.
    statement = ""
    for line in (ROOT / filename).read_text(encoding="utf-8").splitlines(keepends=True):
        statement += line
        if sqlite3.complete_statement(statement):
            yield statement
            statement = ""
    if statement.strip():
        raise ValueError(f"Unterminated SQL statement in {filename}")


def markdown_table(headers, rows):
    def display_value(header, value):
        if value is None:
            return ""
        if header.endswith(("_usd", "_pct")):
            return f"{value:.2f}"
        return str(value).replace("|", r"\|")

    print("| " + " | ".join(headers) + " |")
    print("| " + " | ".join("---" for _ in headers) + " |")
    for row in rows:
        values = (display_value(header, value) for header, value in zip(headers, row, strict=True))
        print("| " + " | ".join(values) + " |")
    print()


def print_report(connection, before, after):
    print("# Task 2 query results\n")
    print(f"Executed on SQLite {sqlite3.sqlite_version} using the packaged Task 1 data.\n")
    print("## Loaded rows\n")
    markdown_table(
        ("table", "rows"),
        ((table, connection.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0])
         for table in TABLES),
    )
    for number, (title, statement) in enumerate(
        zip(REPORT_TITLES, statements("queries.sql"), strict=True), start=1
    ):
        cursor = connection.execute(statement)
        print(f"## {number}. {title}\n")
        markdown_table(tuple(column[0] for column in cursor.description), cursor)

    print("## Query plans before and after indexing\n")
    markdown_table(("Query", "Before indexes", "After indexes"), (
        (label, " · ".join(old), " · ".join(new))
        for label, old, new in zip(PLAN_LABELS, before, after, strict=True)
    ))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, help="Create a new SQLite file at this path")
    options = parser.parse_args()
    if sqlite3.sqlite_version_info < (3, 37, 0):
        parser.exit(1, "SQLite 3.37 or newer is required.\n")

    database = options.database
    if database is not None:
        try:
            # Reserve a new path. Repeating the command cannot overwrite a database.
            with database.open("xb"):
                pass
        except OSError as error:
            parser.exit(1, f"Cannot create a new database at {database}: {error.strerror}\n")

    with closing(sqlite3.connect(database if database is not None else ":memory:")) as connection:
        connection.executescript((ROOT / "schema.sql").read_text(encoding="utf-8"))
        load_data(connection)
        plans = list(statements("index_plans.sql"))
        connection.execute("ANALYZE")
        before = [[row[3] for row in connection.execute(plan)] for plan in plans]
        connection.executescript((ROOT / "indexes.sql").read_text(encoding="utf-8"))
        connection.execute("ANALYZE")
        after = [[row[3] for row in connection.execute(plan)] for plan in plans]
        print_report(connection, before, after)


if __name__ == "__main__":
    main()
