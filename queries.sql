-- queries.sql
-- Retail Sales & Customer Intelligence — Duka Smart Electronics
-- All 46 answers. Run connected to retail_analytics.
--
-- Business rules used throughout:
--   revenue = quantity * unit_price * (1 - discount / 100)   (discount is a percentage)
--   cost    = quantity * cost_price
--   profit  = revenue - cost
--   margin% = profit / NULLIF(revenue, 0) * 100
--   * Money questions (revenue, cost, profit, spending, averages) use Completed orders only.
--   * Order counts include every order, whatever its status.
--   * Customer counts count distinct customers.
--   * "Today" is the latest order_date in the data, not the computer's date.
--   * A month is year + month: DATE_TRUNC('month', order_date).
--   * Money is rounded to 2 decimal places.


-- =====================================================================
-- Section A — SQL fundamentals
-- =====================================================================

-- Q1: Retrieve all customer records
-- Note: SELECT * returns every column for every customer
SELECT *
FROM customers
ORDER BY customer_id;

-- Q2: Display customer names, cities, and segments
-- Note: Pick only the three columns we need
SELECT customer_name, city, customer_segment
FROM customers
ORDER BY customer_name;

-- Q3: Find customers living in Nairobi
-- Note: WHERE keeps only the rows where the city is Nairobi
SELECT *
FROM customers
WHERE city = 'Nairobi'
ORDER BY customer_name;

-- Q4: Find customers registered after January 1, 2025
-- Note: Later dates count as greater, so > keeps everyone who joined after 1 Jan 2025
SELECT *
FROM customers
WHERE registration_date > DATE '2025-01-01'
ORDER BY registration_date;

-- Q5: Display all unique customer cities
-- Note: DISTINCT removes duplicate cities
SELECT DISTINCT city
FROM customers
ORDER BY city;

-- Q6: Retrieve the 10 most recent orders
-- (order_id breaks ties between orders placed on the same day)
-- Note: Sort newest first, then keep the top 10 rows
SELECT *
FROM orders
ORDER BY order_date DESC, order_id DESC
LIMIT 10;

-- Q7: Find orders with unit prices above KSh 10,000
-- Note: Filter on the price before discount
SELECT *
FROM orders
WHERE unit_price > 10000
ORDER BY unit_price DESC, order_id;

-- Q8: Find customers whose names start with A
-- Note: LIKE 'A%' means: starts with A, anything after
SELECT *
FROM customers
WHERE customer_name LIKE 'A%'
ORDER BY customer_name;

-- Q9: Retrieve orders with quantities between 2 and 5
-- Note: BETWEEN includes both ends (2 and 5)
SELECT *
FROM orders
WHERE quantity BETWEEN 2 AND 5
ORDER BY quantity, order_id;

-- Q10: Find orders paid through M-Pesa
-- Note: Exact match on the payment method
SELECT *
FROM orders
WHERE payment_method = 'M-Pesa'
ORDER BY order_date, order_id;


-- =====================================================================
-- Section B — Aggregation and grouping
-- =====================================================================

-- Q11: Count all customers
-- Note: COUNT counts the rows: one row = one customer
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM customers;

-- Q12: Count all orders (every status)
-- Note: No WHERE, so every order counts, whatever its status
SELECT COUNT(*) AS total_orders
FROM orders;

-- Q13: Calculate completed-order revenue
-- Note: Revenue formula worked out for each order, then added up; Completed orders only
SELECT ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS completed_revenue
FROM orders
WHERE order_status = 'Completed';

-- Q14: Calculate the average completed-order value
-- (average revenue of one completed order)
-- Note: AVG of the revenue of each completed order
SELECT ROUND(AVG(quantity * unit_price * (1 - discount / 100)), 2) AS avg_completed_order_value
FROM orders
WHERE order_status = 'Completed';

-- Q15: Find the highest and lowest product prices
-- (unit_price is the list price before discount; each product has one price)
-- Note: The subqueries find the highest and lowest price; the outer query shows which products have them
SELECT DISTINCT product_name, product_category, unit_price,
       CASE WHEN unit_price = (SELECT MAX(unit_price) FROM orders) THEN 'Highest'
            ELSE 'Lowest' END AS price_position
FROM orders
WHERE unit_price = (SELECT MAX(unit_price) FROM orders)
   OR unit_price = (SELECT MIN(unit_price) FROM orders)
ORDER BY unit_price DESC;

-- Q16: Calculate revenue by product category
-- Note: GROUP BY gives one revenue total per category
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY revenue DESC;

-- Q17: Count customers by city
-- Note: One row per city with its number of customers
SELECT city, COUNT(DISTINCT customer_id) AS customers
FROM customers
GROUP BY city
ORDER BY customers DESC, city;

-- Q18: Calculate quantity sold by product
-- "Sold" = units in Completed orders; pending and cancelled orders are not sales.
-- Note: Add up the units for each product
SELECT product_name, product_category, SUM(quantity) AS units_sold
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_name, product_category
ORDER BY units_sold DESC, product_name;

-- Q19: Find categories generating more than KSh 100,000 in revenue
-- Note: HAVING filters the groups after they are totalled (WHERE cannot do that)
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
HAVING SUM(quantity * unit_price * (1 - discount / 100)) > 100000
ORDER BY revenue DESC;

-- Q20: Calculate the percentage of cancelled orders (out of all orders)
-- Note: CASE gives 1 for a cancelled order and 0 otherwise, so SUM counts the cancelled ones;
-- 100.0 avoids integer division
SELECT SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
       COUNT(*)                                                    AS total_orders,
       ROUND(100.0 * SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                                   AS cancelled_pct
FROM orders;


-- =====================================================================
-- Section C — Joins and customer analytics
-- =====================================================================

-- Q21: Display orders with customer names and cities
-- Note: JOIN matches each order to its customer through customer_id
SELECT o.order_id, o.order_date, c.customer_name, c.city,
       o.product_name, o.quantity, o.order_status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date, o.order_id;

-- Q22: Calculate total spending by customer (Completed orders)
-- Note: Join the tables, keep Completed orders, then total per customer
SELECT c.customer_id, c.customer_name,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spending DESC;

-- Q23: Identify customers who have never ordered (no order of any status)
-- Note: LEFT JOIN keeps every customer; no matching order means order_id is NULL
SELECT c.*
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Q24: Find the 10 highest-spending customers
-- Note: Same totals as Q22, sorted highest first, top 10 only
SELECT c.customer_id, c.customer_name, c.city, c.customer_segment,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name, c.city, c.customer_segment
ORDER BY total_spending DESC
LIMIT 10;

-- Q25: Calculate revenue by customer city
-- Note: City comes from customers, revenue comes from orders
SELECT c.city,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.city
ORDER BY revenue DESC;

-- Q26: Identify customers with more than five orders (every status counts)
-- Note: Count each customer's orders; HAVING keeps those with more than 5
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 5
ORDER BY order_count DESC, c.customer_id;

-- Q27: Calculate average customer spending by segment
-- Definition: total Completed spending per customer first, then the average of those
-- totals within each segment. Only customers who bought something are included.
-- Note: Step 1 (CTE): total per customer. Step 2: average those totals per segment
WITH customer_spend AS (
    SELECT c.customer_id, c.customer_segment,
           SUM(o.quantity * o.unit_price * (1 - o.discount / 100)) AS total_spending
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_segment
)
SELECT customer_segment,
       COUNT(*)                       AS purchasing_customers,
       ROUND(AVG(total_spending), 2)  AS avg_spending_per_customer
FROM customer_spend
GROUP BY customer_segment
ORDER BY avg_spending_per_customer DESC;

-- Q28: Identify the most popular category among VIP customers
-- "Popular" = the most orders placed (every status), with units as a tie-breaker.
-- RANK keeps every category if two are tied for first.
-- Note: Step 1: VIP orders per category. Step 2: rank the categories and keep rank 1
WITH vip_categories AS (
    SELECT o.product_category,
           COUNT(o.order_id) AS order_count,
           SUM(o.quantity)   AS units
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE c.customer_segment = 'VIP'
    GROUP BY o.product_category
),
ranked AS (
    SELECT *, RANK() OVER (ORDER BY order_count DESC, units DESC) AS rnk
    FROM vip_categories
)
SELECT product_category, order_count, units
FROM ranked
WHERE rnk = 1;


-- =====================================================================
-- Section D — Subqueries and CTEs
-- =====================================================================

-- Q29: Find customers spending above the average total spending per purchasing customer
-- Note: Uses subqueries instead of a CTE. The subquery in FROM totals each customer;
-- the nested subquery in WHERE works out the average of those totals to compare against
SELECT c.customer_id, c.customer_name,
       ROUND(t.total_spending, 2) AS total_spending
FROM (
    SELECT customer_id,
           SUM(quantity * unit_price * (1 - discount / 100)) AS total_spending
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
) AS t
JOIN customers c ON c.customer_id = t.customer_id
WHERE t.total_spending > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(quantity * unit_price * (1 - discount / 100)) AS customer_total
        FROM orders
        WHERE order_status = 'Completed'
        GROUP BY customer_id
    ) AS totals
)
ORDER BY t.total_spending DESC;

-- Q30: Find products priced above the overall average unit price
-- (average taken over every order line)
-- Note: The subquery gives the average price; keep the products above it
SELECT DISTINCT product_name, product_category, unit_price,
       ROUND((SELECT AVG(unit_price) FROM orders), 2) AS overall_avg_price
FROM orders
WHERE unit_price > (SELECT AVG(unit_price) FROM orders)
ORDER BY unit_price DESC;

-- Q31: Use a CTE to identify the three highest-revenue months
-- Note: The CTE builds revenue per month; sort it and keep the top 3
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date                    AS month,
           SUM(quantity * unit_price * (1 - discount / 100))        AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT TO_CHAR(month, 'YYYY-MM') AS month, ROUND(revenue, 2) AS revenue
FROM monthly
ORDER BY revenue DESC
LIMIT 3;

-- Q32: Find customers purchasing from at least three categories
-- (purchases = Completed orders)
-- Note: COUNT(DISTINCT ...) counts the different categories each customer bought from
SELECT c.customer_id, c.customer_name,
       COUNT(DISTINCT o.product_category) AS categories_bought
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.product_category) >= 3
ORDER BY categories_bought DESC, c.customer_id;

-- Q33: Use a CTE to calculate category revenue, cost, profit, and profit margin
-- Note: The CTE totals revenue and cost per category; the outer query works out profit and margin
WITH category_totals AS (
    SELECT product_category,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue,
           SUM(quantity * cost_price)                        AS cost
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category
)
SELECT product_category,
       ROUND(revenue, 2)                                         AS revenue,
       ROUND(cost, 2)                                            AS cost,
       ROUND(revenue - cost, 2)                                  AS profit,
       ROUND((revenue - cost) / NULLIF(revenue, 0) * 100, 2)     AS profit_margin_pct
FROM category_totals
ORDER BY profit DESC;

-- Q34: Find customers whose latest completed order is more than 90 days
--      before the latest order date in the dataset
-- Note: The CTE finds each customer's last completed order; subtracting two dates gives days
WITH last_completed AS (
    SELECT customer_id, MAX(order_date) AS last_order
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name, c.city, c.customer_segment,
       lc.last_order,
       (SELECT MAX(order_date) FROM orders) - lc.last_order AS days_since_last_order
FROM last_completed lc
JOIN customers c ON c.customer_id = lc.customer_id
WHERE (SELECT MAX(order_date) FROM orders) - lc.last_order > 90
ORDER BY days_since_last_order DESC;


-- =====================================================================
-- Section E — Window functions
-- =====================================================================

-- Q35: Rank customers by spending using RANK()
-- Note: RANK gives equal spenders the same rank and skips the next number
WITH customer_spend AS (
    SELECT c.customer_id, c.customer_name,
           SUM(o.quantity * o.unit_price * (1 - o.discount / 100)) AS total_spending
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name,
       ROUND(total_spending, 2)                         AS total_spending,
       RANK() OVER (ORDER BY total_spending DESC)       AS spending_rank
FROM customer_spend
ORDER BY spending_rank, customer_id;

-- Q36: Number each customer's orders by recency using ROW_NUMBER()
-- (1 = most recent; every status)
-- Note: PARTITION BY restarts the numbering for each customer
SELECT customer_id, order_id, order_date, product_name, order_status,
       ROW_NUMBER() OVER (PARTITION BY customer_id
                          ORDER BY order_date DESC, order_id DESC) AS recency_number
FROM orders
ORDER BY customer_id, recency_number;

-- Q37: Rank products within categories using DENSE_RANK()
-- (by Completed revenue)
-- Note: DENSE_RANK restarts for each category and does not skip numbers after a tie
WITH product_revenue AS (
    SELECT product_category, product_name,
           SUM(quantity * unit_price * (1 - discount / 100)) AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY product_category, product_name
)
SELECT product_category, product_name,
       ROUND(revenue, 2) AS revenue,
       DENSE_RANK() OVER (PARTITION BY product_category ORDER BY revenue DESC) AS rank_in_category
FROM product_revenue
ORDER BY product_category, rank_in_category;

-- Q38: Calculate cumulative monthly revenue
-- Note: SUM ... OVER (ORDER BY month) adds each month to all the months before it
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date              AS month,
           SUM(quantity * unit_price * (1 - discount / 100))  AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT TO_CHAR(month, 'YYYY-MM')                     AS month,
       ROUND(revenue, 2)                             AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2)  AS cumulative_revenue
FROM monthly
ORDER BY month;

-- Q39: Compare monthly revenue using LAG()
-- Note: LAG looks back one row to the previous month's revenue
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date              AS month,
           SUM(quantity * unit_price * (1 - discount / 100))  AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT TO_CHAR(month, 'YYYY-MM')                                  AS month,
       ROUND(revenue, 2)                                          AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2)               AS previous_month_revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)     AS change
FROM monthly
ORDER BY month;

-- Q40: Calculate month-over-month revenue growth (%)
-- Note: Growth % = (this month - last month) / last month * 100
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date              AS month,
           SUM(quantity * unit_price * (1 - discount / 100))  AS revenue
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY DATE_TRUNC('month', order_date)
),
with_previous AS (
    SELECT month, revenue, LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly
)
SELECT TO_CHAR(month, 'YYYY-MM')   AS month,
       ROUND(revenue, 2)           AS revenue,
       ROUND(previous_revenue, 2)  AS previous_revenue,
       ROUND((revenue - previous_revenue) / NULLIF(previous_revenue, 0) * 100, 2) AS mom_growth_pct
FROM with_previous
ORDER BY month;

-- Q41: Divide customers into four spending groups using NTILE(4)
-- (group 1 = highest spenders; purchasing customers only)
-- Note: NTILE(4) splits the customers, sorted by spending, into four equal groups
WITH customer_spend AS (
    SELECT c.customer_id, c.customer_name,
           SUM(o.quantity * o.unit_price * (1 - o.discount / 100)) AS total_spending
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name,
       ROUND(total_spending, 2)                       AS total_spending,
       NTILE(4) OVER (ORDER BY total_spending DESC)   AS spending_group
FROM customer_spend
ORDER BY spending_group, total_spending DESC;

-- Q42: Calculate each category's share of total revenue using window functions
-- Note: SUM(SUM(...)) OVER () puts the grand total on every row so each category can be divided by it
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2) AS revenue,
       ROUND(100.0 * SUM(quantity * unit_price * (1 - discount / 100))
             / SUM(SUM(quantity * unit_price * (1 - discount / 100))) OVER (), 2) AS revenue_share_pct
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY revenue DESC;


-- =====================================================================
-- Section F — Advanced business intelligence
-- =====================================================================

-- Q43: Create a monthly_sales_summary view (month, orders, revenue, cost, profit),
--      then select from it.
-- orders counts every order placed that month; revenue, cost and profit are Completed only.
-- Note: A view saves a query under a name so it can be selected like a table
CREATE OR REPLACE VIEW monthly_sales_summary AS
SELECT DATE_TRUNC('month', order_date)::date AS month,
       COUNT(*)                              AS orders,
       ROUND(COALESCE(SUM(quantity * unit_price * (1 - discount / 100))
             FILTER (WHERE order_status = 'Completed'), 0), 2) AS revenue,
       ROUND(COALESCE(SUM(quantity * cost_price)
             FILTER (WHERE order_status = 'Completed'), 0), 2) AS cost,
       ROUND(COALESCE(SUM(quantity * unit_price * (1 - discount / 100) - quantity * cost_price)
             FILTER (WHERE order_status = 'Completed'), 0), 2) AS profit
FROM orders
GROUP BY DATE_TRUNC('month', order_date);

SELECT TO_CHAR(month, 'YYYY-MM') AS month, orders, revenue, cost, profit
FROM monthly_sales_summary
ORDER BY month;

-- Q44: PL/pgSQL function: completed-order revenue for a supplied customer ID.
-- Returns 0 (not NULL) for a customer with no completed orders or an ID that does not exist.
-- In DBeaver, run the CREATE FUNCTION statement on its own (select it, Ctrl+Enter).
-- Note: COALESCE turns NULL (no completed orders) into 0
CREATE OR REPLACE FUNCTION customer_completed_revenue(p_customer_id INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_revenue NUMERIC;
BEGIN
    SELECT COALESCE(SUM(quantity * unit_price * (1 - discount / 100)), 0)
    INTO v_revenue
    FROM orders
    WHERE customer_id = p_customer_id
      AND order_status = 'Completed';

    RETURN ROUND(v_revenue, 2);
END;
$$;

-- An existing customer (the top spender from Q24) ...
SELECT customer_id, customer_name, customer_completed_revenue(customer_id) AS completed_revenue
FROM customers
ORDER BY completed_revenue DESC
LIMIT 1;

-- ... and an ID that does not exist (returns 0)
SELECT customer_completed_revenue(99999) AS completed_revenue_for_missing_id;

-- Q45: Segment customers into High, Medium and Low Value
-- Thresholds: round KSh amounts of total Completed spending per customer.
--   High   = KSh 250,000 or more
--   Medium = KSh 50,000 to 249,999
--   Low    = under KSh 50,000, including customers with no completed purchase
-- Why: I chose these after looking at the spending list from Q22. KSh 250,000 is about four
-- HP laptops (KSh 62,999 each), so it marks customers who buy big items again and again;
-- under KSh 50,000 is less than one laptop, mostly accessories or a single budget phone.
-- Round figures are easy for management to remember and use.
-- Note: Step 1 (CTE): spending per customer, 0 if they never completed an order.
-- Step 2: CASE puts each customer in a band
WITH customer_spend AS (
    SELECT c.customer_id, c.customer_name, c.customer_segment,
           COALESCE(SUM(o.quantity * o.unit_price * (1 - o.discount / 100))
                    FILTER (WHERE o.order_status = 'Completed'), 0) AS total_spending
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name, c.customer_segment
)
SELECT customer_id, customer_name, customer_segment,
       ROUND(total_spending, 2) AS total_spending,
       CASE WHEN total_spending >= 250000 THEN 'High Value'
            WHEN total_spending >= 50000  THEN 'Medium Value'
            ELSE 'Low Value' END AS value_band
FROM customer_spend
ORDER BY total_spending DESC;

-- Q46: Management report
-- (a) Top five customers by Completed spending
-- Note: Same as Q24, but the top 5
SELECT c.customer_name, c.city, c.customer_segment,
       ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount / 100)), 2) AS total_spending
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name, c.city, c.customer_segment
ORDER BY total_spending DESC
LIMIT 5;

-- (b) Top five products by Completed revenue
-- Note: Group by product, sort by revenue, keep the top 5
SELECT product_name, product_category,
       SUM(quantity)                                                AS units_sold,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100)), 2)  AS revenue,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100) - quantity * cost_price), 2) AS profit
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_name, product_category
ORDER BY revenue DESC
LIMIT 5;

-- (c) Most profitable category
-- Note: Profit per category, keep the highest
SELECT product_category,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100) - quantity * cost_price), 2) AS profit,
       ROUND(SUM(quantity * unit_price * (1 - discount / 100) - quantity * cost_price)
             / NULLIF(SUM(quantity * unit_price * (1 - discount / 100)), 0) * 100, 2)      AS profit_margin_pct
FROM orders
WHERE order_status = 'Completed'
GROUP BY product_category
ORDER BY profit DESC
LIMIT 1;

-- (d) Lowest-revenue month (from the Q43 view)
-- Note: Read the view from Q43, lowest revenue first
SELECT TO_CHAR(month, 'YYYY-MM') AS month, orders, revenue, profit
FROM monthly_sales_summary
ORDER BY revenue ASC
LIMIT 1;
