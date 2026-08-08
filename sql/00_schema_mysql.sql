-- ==========================================================================
-- Sales Performance Dashboard - Database Schema (Star Schema) 
-- ==========================================================================

CREATE DATABASE superstore;
USE superstore;

CREATE TABLE dim_customers (
    customer_id     VARCHAR(10) PRIMARY KEY,
    customer_name   VARCHAR(50) NOT NULL,
    segment         VARCHAR(20) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE dim_products (
    product_id      VARCHAR(20)  PRIMARY KEY,
    product_name    VARCHAR(255) NOT NULL,
    category        VARCHAR(20)  NOT NULL,         -- Furniture / Office Supplies / Technology
    sub_category    VARCHAR(20)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE dim_locations (
    location_id     INT          PRIMARY KEY,
    city            VARCHAR(50),
    state           VARCHAR(30),
    region          VARCHAR(10),                   -- East / West / Central / South
    postal_code     INT,
    country         VARCHAR(20)
) ENGINE=InnoDB;

CREATE TABLE fact_orders (
    row_id           INT          PRIMARY KEY,
    order_id         VARCHAR(20)  NOT NULL,
    order_date       DATE         NOT NULL,
    ship_date        DATE         NOT NULL,
    ship_mode        VARCHAR(20),
    customer_id      VARCHAR(10),
    product_id       VARCHAR(20),
    location_id      INT,
    sales            DECIMAL(12,2) NOT NULL,
    quantity         INT          NOT NULL,
    discount         DECIMAL(5,2) NOT NULL,
    profit           DECIMAL(12,2) NOT NULL,
    profit_margin    DECIMAL(8,4),
    order_year       INT,
    order_month      INT,
    order_month_name VARCHAR(10),
    order_quarter    INT,
    order_weekday    VARCHAR(10),
    shipping_days    INT,
    sales_bucket     VARCHAR(20),
    discount_tier    VARCHAR(20),
    is_profitable    TINYINT,                      -- 1 = profitable, 0 = loss
    CONSTRAINT fk_fact_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    CONSTRAINT fk_fact_product  FOREIGN KEY (product_id)  REFERENCES dim_products(product_id),
    CONSTRAINT fk_fact_location FOREIGN KEY (location_id) REFERENCES dim_locations(location_id)
) ENGINE=InnoDB;

CREATE INDEX idx_fact_customer ON fact_orders(customer_id);
CREATE INDEX idx_fact_product  ON fact_orders(product_id);
CREATE INDEX idx_fact_location ON fact_orders(location_id);
CREATE INDEX idx_fact_date     ON fact_orders(order_date);