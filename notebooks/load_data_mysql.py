"""
Load the cleaned Superstore dataset into MySQL.

Prerequisites:
1. MySQL Server is running.
2. Database `superstore` has been created.
3. MySQL schema has been executed using `00_schema_mysql.sql`.
4. Required Python packages are installed:
       pip install pandas sqlalchemy pymysql

Usage:
    python load_data_mysql.py

The script:
- Reads the cleaned Superstore CSV.
- Creates dimension tables from the dataset.
- Creates the fact table.
- Loads dimensions before the fact table to satisfy foreign-key constraints.
"""

import os

import pandas as pd
from sqlalchemy import create_engine


# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

DB_USER = os.environ.get("MYSQL_USER", "root")
DB_PASSWORD = os.environ.get("MYSQL_PASSWORD")
DB_HOST = os.environ.get("MYSQL_HOST", "localhost")
DB_NAME = os.environ.get("MYSQL_DATABASE", "superstore")

CSV_PATH = "data/cleaned/Superstore_Cleaned.csv"


if not DB_PASSWORD:
    raise ValueError(
        "MYSQL_PASSWORD environment variable is not set. "
        "Please set your MySQL password before running the script."
    )


# =============================================================================
# DATABASE CONNECTION
# =============================================================================

DATABASE_URL = (
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}/{DB_NAME}"
)

engine = create_engine(DATABASE_URL)


# =============================================================================
# LOAD CLEANED DATA
# =============================================================================

df = pd.read_csv(
    CSV_PATH,
    parse_dates=["Order Date", "Ship Date"]
)


# =============================================================================
# CREATE DIMENSION TABLES
# =============================================================================

# Customer dimension
customers = (
    df[["Customer ID", "Customer Name", "Segment"]]
    .drop_duplicates(subset=["Customer ID"])
    .rename(
        columns={
            "Customer ID": "customer_id",
            "Customer Name": "customer_name",
            "Segment": "segment",
        }
    )
)


# Product dimension
products = (
    df[["Product ID", "Product Name", "Category", "Sub-Category"]]
    .drop_duplicates(subset=["Product ID"])
    .rename(
        columns={
            "Product ID": "product_id",
            "Product Name": "product_name",
            "Category": "category",
            "Sub-Category": "sub_category",
        }
    )
)


# Location dimension
locations = (
    df[["City", "State", "Region", "Postal Code", "Country"]]
    .drop_duplicates()
    .reset_index(drop=True)
)

locations["location_id"] = locations.index + 1


# =============================================================================
# CREATE FACT TABLE
# =============================================================================

fact = df.merge(
    locations,
    on=["City", "State", "Region", "Postal Code", "Country"],
    how="left"
)


# Rename location columns
locations = locations.rename(
    columns={
        "City": "city",
        "State": "state",
        "Region": "region",
        "Postal Code": "postal_code",
        "Country": "country",
    }
)


# Rename fact-table columns
fact = fact.rename(
    columns={
        "Row ID": "row_id",
        "Order ID": "order_id",
        "Order Date": "order_date",
        "Ship Date": "ship_date",
        "Ship Mode": "ship_mode",
        "Customer ID": "customer_id",
        "Product ID": "product_id",
        "Sales": "sales",
        "Quantity": "quantity",
        "Discount": "discount",
        "Profit": "profit",
        "Profit_Margin": "profit_margin",
        "Order_Year": "order_year",
        "Order_Month": "order_month",
        "Order_Month_Name": "order_month_name",
        "Order_Quarter": "order_quarter",
        "Order_Weekday": "order_weekday",
        "Shipping_Days": "shipping_days",
        "Sales_Bucket": "sales_bucket",
        "Discount_Tier": "discount_tier",
        "Is_Profitable": "is_profitable",
    }
)


# Select columns matching the MySQL fact_orders schema
fact = fact[
    [
        "row_id",
        "order_id",
        "order_date",
        "ship_date",
        "ship_mode",
        "customer_id",
        "product_id",
        "location_id",
        "sales",
        "quantity",
        "discount",
        "profit",
        "profit_margin",
        "order_year",
        "order_month",
        "order_month_name",
        "order_quarter",
        "order_weekday",
        "shipping_days",
        "sales_bucket",
        "discount_tier",
        "is_profitable",
    ]
]


# MySQL TINYINT expects integer values
fact["is_profitable"] = fact["is_profitable"].astype(int)


# =============================================================================
# LOAD DATA INTO MYSQL
# =============================================================================

# Load dimension tables first because fact_orders
# contains foreign-key references to them.

customers.to_sql(
    "dim_customers",
    engine,
    if_exists="append",
    index=False
)

products.to_sql(
    "dim_products",
    engine,
    if_exists="append",
    index=False
)

locations.to_sql(
    "dim_locations",
    engine,
    if_exists="append",
    index=False
)

fact.to_sql(
    "fact_orders",
    engine,
    if_exists="append",
    index=False,
    chunksize=1000
)


# =============================================================================
# LOAD SUMMARY
# =============================================================================

print("\nLoad complete.")
print(f"  dim_customers: {len(customers)} rows")
print(f"  dim_products:  {len(products)} rows")
print(f"  dim_locations: {len(locations)} rows")
print(f"  fact_orders:   {len(fact)} rows")