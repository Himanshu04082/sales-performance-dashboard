-- ==========================================================================
-- Sales Performance Dashboard - 30 Business SQL Queries
-- ==========================================================================

USE superstore;

-- Q1. Which products generate the highest total revenue?
SELECT p.product_name, p.category, ROUND(SUM(f.sales), 2) AS total_sales
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY total_sales DESC
LIMIT 10;

-- Q2. Which products lose money overall?
SELECT p.product_name, p.sub_category, ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_name, p.sub_category
HAVING SUM(f.profit) < 0
ORDER BY total_profit ASC
LIMIT 15;

-- Q3. Which region performs best by profit margin?
SELECT l.region, ROUND(SUM(f.sales), 2) AS total_sales,
       ROUND(SUM(f.profit), 2) AS total_profit,
       ROUND(SUM(f.profit) * 100.0 / NULLIF(SUM(f.sales), 0), 2) AS profit_margin_pct
FROM fact_orders f
JOIN dim_locations l ON f.location_id = l.location_id
GROUP BY l.region
ORDER BY profit_margin_pct DESC;

-- Q4. Which customers contribute the most revenue?
SELECT c.customer_name, c.segment, ROUND(SUM(f.sales), 2) AS total_sales
FROM fact_orders f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_name, c.segment
ORDER BY total_sales DESC
LIMIT 10;

-- Q5. Which categories should receive more investment?
SELECT p.category, ROUND(SUM(f.sales), 2) AS total_sales,
       ROUND(SUM(f.profit), 2) AS total_profit,
       ROUND(SUM(f.profit) * 100.0 / NULLIF(SUM(f.sales), 0), 2) AS margin_pct,
       COUNT(*) AS order_lines
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY margin_pct DESC;

-- Q6. Which months have peak sales across all years?
SELECT order_month_name, order_month, ROUND(SUM(sales), 2) AS total_sales
FROM fact_orders
GROUP BY order_month_name, order_month
ORDER BY order_month;

-- Q7. Which products have high discounts but low/negative profit?
SELECT p.product_name, f.discount, f.profit
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
WHERE f.discount >= 0.40 AND f.profit < 0
ORDER BY f.profit ASC
LIMIT 15;

-- Q8. Which states need profitability improvement?
SELECT l.state, ROUND(SUM(f.sales), 2) AS total_sales,
       ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_orders f
JOIN dim_locations l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_profit ASC
LIMIT 10;

-- Q9. Which customer segments are most valuable per order?
SELECT c.segment, COUNT(DISTINCT f.order_id) AS num_orders,
       ROUND(AVG(f.sales), 2) AS avg_order_line_value,
       ROUND(SUM(f.profit) / NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_profit_per_order
FROM fact_orders f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY avg_profit_per_order DESC;

-- Q10. How are order lines distributed across profitability tiers?
SELECT CASE
           WHEN profit < 0 THEN 'Loss'
           WHEN profit < 50 THEN 'Low Profit'
           WHEN profit < 200 THEN 'Medium Profit'
           ELSE 'High Profit'
       END AS profit_tier,
       COUNT(*) AS num_orders,
       ROUND(SUM(sales), 2) AS total_sales
FROM fact_orders
GROUP BY profit_tier
ORDER BY total_sales DESC;

-- Q11. What is the monthly revenue trend?
SELECT order_year, order_month, ROUND(SUM(sales), 2) AS monthly_revenue
FROM fact_orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

-- Q12. What is the year-over-year revenue growth?
WITH yearly AS (
    SELECT order_year, SUM(sales) AS total_sales
    FROM fact_orders
    GROUP BY order_year
)
SELECT order_year, ROUND(total_sales, 2) AS total_sales,
       ROUND(total_sales - LAG(total_sales) OVER (ORDER BY order_year), 2) AS yoy_change,
       ROUND((total_sales - LAG(total_sales) OVER (ORDER BY order_year)) * 100.0 /
             NULLIF(LAG(total_sales) OVER (ORDER BY order_year), 0), 2) AS yoy_growth_pct
FROM yearly
ORDER BY order_year;

-- Q13. What is the running total of sales by month?
WITH monthly AS (
    SELECT order_year, order_month, SUM(sales) AS monthly_sales
    FROM fact_orders
    GROUP BY order_year, order_month
)
SELECT order_year, order_month, ROUND(monthly_sales, 2) AS monthly_sales,
       ROUND(SUM(monthly_sales) OVER (ORDER BY order_year, order_month), 2) AS running_total
FROM monthly
ORDER BY order_year, order_month;

-- Q14. How do regions rank by total profit?
SELECT l.region, ROUND(SUM(f.profit), 2) AS total_profit,
       RANK() OVER (ORDER BY SUM(f.profit) DESC) AS profit_rank
FROM fact_orders f
JOIN dim_locations l ON f.location_id = l.location_id
GROUP BY l.region
ORDER BY profit_rank;

-- Q15. What share of total revenue comes from each category?
SELECT p.category, ROUND(SUM(f.sales), 2) AS category_sales,
       ROUND(SUM(f.sales) * 100.0 / NULLIF(SUM(SUM(f.sales)) OVER (), 0), 2) AS pct_of_total_sales
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY category_sales DESC;

-- Q16. What is the average order value (AOV)?
SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT order_id, SUM(sales) AS order_total
    FROM fact_orders
    GROUP BY order_id
) AS orders;

-- Q17. How many customers are repeat customers?
SELECT COUNT(*) AS repeat_customer_count
FROM (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM fact_orders
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) > 1
) AS repeat_customers;

-- Q18. What is the revenue contribution of repeat vs one-time customers?
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM fact_orders
    GROUP BY customer_id
),
customer_type AS (
    SELECT customer_id,
           CASE WHEN order_count > 1 THEN 'Repeat' ELSE 'One-Time' END AS customer_type
    FROM customer_orders
)
SELECT ct.customer_type, ROUND(SUM(f.sales), 2) AS total_sales,
       ROUND(SUM(f.sales) * 100.0 / NULLIF(SUM(SUM(f.sales)) OVER (), 0), 2) AS pct_of_revenue
FROM fact_orders f
JOIN customer_type ct ON f.customer_id = ct.customer_id
GROUP BY ct.customer_type
ORDER BY total_sales DESC;

-- Q19. What are the top 5 products within each category?
WITH ranked AS (
    SELECT p.category, p.product_name, SUM(f.sales) AS total_sales,
           ROW_NUMBER() OVER (
               PARTITION BY p.category ORDER BY SUM(f.sales) DESC
           ) AS rn
    FROM fact_orders f
    JOIN dim_products p ON f.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT category, product_name, ROUND(total_sales, 2) AS total_sales
FROM ranked
WHERE rn <= 5
ORDER BY category, rn;

-- Q20. Which customers have average order-line profit below the company average?
SELECT c.customer_name, ROUND(AVG(f.profit), 2) AS avg_profit_per_line
FROM fact_orders f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.customer_name
HAVING AVG(f.profit) < (SELECT AVG(profit) FROM fact_orders)
ORDER BY avg_profit_per_line ASC
LIMIT 15;

-- Q21. How does discount tier affect profit margin?
SELECT discount_tier, COUNT(*) AS order_lines,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit) * 100.0 / NULLIF(SUM(sales), 0), 2) AS margin_pct
FROM fact_orders
GROUP BY discount_tier
ORDER BY margin_pct DESC;

-- Q22. Which shipping modes are most popular and how do they affect order value?
SELECT ship_mode, COUNT(DISTINCT order_id) AS num_orders,
       ROUND(AVG(sales), 2) AS avg_sales,
       ROUND(AVG(shipping_days), 1) AS avg_shipping_days
FROM fact_orders
GROUP BY ship_mode
ORDER BY num_orders DESC;

-- Q23. What are the top 3 sub-categories by profit within each region?
WITH region_subcat AS (
    SELECT l.region, p.sub_category, SUM(f.profit) AS total_profit,
           RANK() OVER (
               PARTITION BY l.region ORDER BY SUM(f.profit) DESC
           ) AS profit_rank
    FROM fact_orders f
    JOIN dim_products p ON f.product_id = p.product_id
    JOIN dim_locations l ON f.location_id = l.location_id
    GROUP BY l.region, p.sub_category
)
SELECT region, sub_category, ROUND(total_profit, 2) AS total_profit, profit_rank
FROM region_subcat
WHERE profit_rank <= 3
ORDER BY region, profit_rank;

-- Q24. What is the month-over-month sales growth rate?
WITH monthly AS (
    SELECT order_year, order_month, SUM(sales) AS monthly_sales
    FROM fact_orders
    GROUP BY order_year, order_month
)
SELECT order_year, order_month, ROUND(monthly_sales, 2) AS monthly_sales,
       ROUND((monthly_sales - LAG(monthly_sales) OVER (ORDER BY order_year, order_month)) * 100.0 /
             NULLIF(LAG(monthly_sales) OVER (ORDER BY order_year, order_month), 0), 2) AS mom_growth_pct
FROM monthly
ORDER BY order_year, order_month;

-- Q25. Which customers purchased from all 3 product categories?
SELECT c.customer_name, COUNT(DISTINCT p.category) AS categories_purchased
FROM fact_orders f
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY c.customer_name
HAVING COUNT(DISTINCT p.category) = 3
ORDER BY c.customer_name
LIMIT 15;

-- Q26. Reusable state-level performance view
DROP VIEW IF EXISTS vw_state_performance;
CREATE VIEW vw_state_performance AS
SELECT l.state, ROUND(SUM(f.sales), 2) AS total_sales,
       ROUND(SUM(f.profit), 2) AS total_profit,
       ROUND(SUM(f.profit) * 100.0 / NULLIF(SUM(f.sales), 0), 2) AS margin_pct,
       COUNT(DISTINCT f.order_id) AS num_orders
FROM fact_orders f
JOIN dim_locations l ON f.location_id = l.location_id
GROUP BY l.state;

SELECT * FROM vw_state_performance
ORDER BY total_profit ASC
LIMIT 10;

-- Q27. Reusable monthly KPI view
DROP VIEW IF EXISTS vw_monthly_kpis;
CREATE VIEW vw_monthly_kpis AS
SELECT order_year, order_month, order_month_name,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit), 2) AS total_profit,
       COUNT(DISTINCT order_id) AS total_orders,
       ROUND(SUM(sales) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value
FROM fact_orders
GROUP BY order_year, order_month, order_month_name;

SELECT * FROM vw_monthly_kpis
ORDER BY order_year, order_month
LIMIT 12;

-- Q28. Which products sell high volumes but have negative total profit?
SELECT p.product_name, SUM(f.quantity) AS total_units_sold,
       ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
GROUP BY p.product_name
HAVING SUM(f.quantity) > 20 AND SUM(f.profit) < 0
ORDER BY total_units_sold DESC;

-- Q29. Which orders took unusually long to ship?
SELECT order_id, ship_mode, shipping_days
FROM fact_orders
WHERE shipping_days > (SELECT AVG(shipping_days) + 3 FROM fact_orders)
ORDER BY shipping_days DESC
LIMIT 15;

-- Q30. Yearly profit report by category
-- Change @report_year to analyse another year.
SET @report_year = 2018;

SELECT p.category, ROUND(SUM(f.sales), 2) AS total_sales,
       ROUND(SUM(f.profit), 2) AS total_profit
FROM fact_orders f
JOIN dim_products p ON f.product_id = p.product_id
WHERE f.order_year = @report_year
GROUP BY p.category
ORDER BY total_profit DESC;
