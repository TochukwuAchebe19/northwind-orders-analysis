-- A. Basic Data Exploration (Orders Table)-- 

-- How many total orders are in the dataset?--
SELECT COUNT(*) 
FROM northwind_orders;

-- How many unique customers placed orders?--
SELECT COUNT(DISTINCT customer_id)
FROM northwind_orders;

-- List the first and last order dates in the dataset.--
SELECT order_date
FROM northwind_orders 
ORDER BY order_date DESC
LIMIT 1; 

SELECT order_date
FROM northwind_orders 
ORDER BY order_date ASC
LIMIT 1; 

-- Which countries placed the most orders?--
SELECT ship_country,
COUNT(*) AS most_orders
FROM northwind_orders
GROUP BY ship_country 
ORDER BY most_orders DESC;

-- What’s the total number of orders per year?--
SELECT YEAR(order_date) AS Total_orders, 
COUNT(*)
FROM northwind_orders
GROUP BY YEAR(order_date);

-- Which employees handled the most orders?--
 SELECT employee_id,
 COUNT(*) AS most_orders
 FROM northwind_orders
 GROUP BY employee_id
 ORDER BY most_orders DESC;
 
-- How many orders were shipped late (where shipped_date > required_date)?--
SELECT COUNT(shipped_date)
FROM northwind_orders
WHERE shipped_date > required_date;

-- What percentage of all orders were shipped on time?--
SELECT 
ROUND((COUNT(CASE WHEN shipped_date <= required_date THEN 1 END) / COUNT(*)) * 100, 2) AS percent_on_time
FROM northwind_orders;

-- What’s the average freight (shipping cost) per order?--
SELECT AVG(freight)
FROM northwind_orders;

-- Which 5 countries had the highest average freight costs?--
SELECT ship_country, AVG(freight)
FROM northwind_orders
GROUP BY ship_country
ORDER BY AVG(freight) DESC limit 5;

-- B. Order Details Analysis (Product-Level Metrics)-- 

SELECT * FROM northwind_order_details;

-- How many unique products were sold in total?--
SELECT COUNT(DISTINCT(product_id)) 
FROM northwind_order_details;

-- What is the total quantity sold (sum of all units)?--
SELECT SUM(quantity)
FROM northwind_order_details;

-- Which product had the highest total quantity sold?--
SELECT SUM(quantity), product_id
FROM northwind_order_details
GROUP BY product_id
ORDER BY SUM(quantity) DESC
LIMIT 1; 

-- What is the average discount given across all orders?--
SELECT AVG(discount)
FROM northwind_order_details;

-- List the top 10 products by total revenue (unit_price * quantity * (1 - discount)).--
SELECT product_id, SUM(unit_price * quantity * (1-discount)) AS total_revenue
FROM northwind_order_details
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- C. JOIN-Based Analysis (Orders + Order_Details)-- 
-- Join orders and order_details to calculate the total sales amount per order.--
SELECT P.order_id, round(SUM(P.total_sales),2)
FROM(
SELECT a.order_id, b.quantity * b.unit_price * (1 - b.discount) AS total_sales
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id)P
GROUP BY P.order_id;

-- What is the total revenue by country (joining on orders.ship_country)?--
SELECT P.ship_country, round(SUM(P.total_revenue),2)
FROM(
SELECT c.ship_country, s.quantity * s.unit_price * (1- s.discount) AS total_revenue
FROM northwind_orders c
JOIN northwind_order_details s
ON c.order_id = s.order_id)P
GROUP BY  P.ship_country;

-- What is the average order value (AOV) per country?--
SELECT C.ship_country, round(AVG(average_order_value),2) AS avg_order_value 
FROM (
SELECT a.ship_country, SUM(b.unit_price * b.quantity * (1 - b.discount)) AS average_order_value 
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
GROUP BY a.order_id, a.ship_country
) C
GROUP BY C.ship_country;


-- Which customers have placed the highest total-value orders?--
SELECT C.customer_id, round(SUM(total_value_orders), 2)
FROM (
SELECT a.customer_id, b.unit_price * b.quantity * (1 - b.discount) AS total_value_orders
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id)C 
GROUP BY C.customer_id
ORDER BY SUM(total_value_orders)DESC; 

-- What is the total number of products sold by month (using order_date)?--
SELECT MONTH(order_date) AS Month, SUM(b.quantity) AS total_products_sold
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id 
GROUP BY Month 
ORDER BY Month; 

-- Which month generated the highest revenue overall?--
SELECT MONTH(order_date) AS Month, SUM(b.quantity * b.unit_price * (1-b.discount)) AS Revenue
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
GROUP BY Month 
ORDER BY Revenue DESC
LIMIT 1;

-- Join orders and order_details to calculate average discount per country.-- 
SELECT a.ship_country, AVG(b.discount)
FROM northwind_orders a 
JOIN northwind_order_details b
ON a.order_id = b.order_id
GROUP BY a.ship_country; 

-- Calculate total quantity and revenue by employee (sales rep performance).--
SELECT a.employee_id, SUM(b.quantity) AS total_quantity, SUM(b.unit_price * b.quantity * (1 - b.discount)) AS total_revenue
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
GROUP BY a.employee_id;

-- Which orders had more than 10 line items (order_details count per order)?--
SELECT a.order_id, COUNT(b.product_id)
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
GROUP BY a.order_id
HAVING COUNT(product_id) > 10;  

-- Which customers have placed more than 5 orders, and what’s their average order value?--
SELECT customer_id, AVG(order_total) AS avg_order_value
FROM (
    SELECT 
      a.customer_id,
      a.order_id,
      SUM(b.unit_price * b.quantity * (1 - b.discount)) AS order_total
    FROM northwind_orders a
    JOIN northwind_order_details b
      ON a.order_id = b.order_id
    GROUP BY a.customer_id, a.order_id
) AS order_summary
GROUP BY customer_id
HAVING COUNT(order_id) > 5;

-- D. Time & Trend Analysis--
-- How does the total monthly revenue trend over time?--
SELECT Month(a.order_date) AS Month, Year(order_date), SUM(b.unit_price * b.quantity * (1-b.discount)) AS Revenue
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
WHERE Year(order_date) IN (1996,1997,1998)
GROUP BY Year(order_date), Month
ORDER BY Year(order_date), Month;

-- What’s the difference in average order value between the first and last year in the dataset?-- 
SELECT 
MAX(CASE WHEN order_year = 1998 THEN Average_order_value END) -
MAX(CASE WHEN order_year = 1996 THEN Average_order_value END) AS difference_in_avg_order_value 
FROM (
SELECT Year(a.order_date) AS order_year, AVG(b.unit_price * b.quantity * (1-b.discount)) AS Average_order_value 
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
WHERE Year(a.order_date) IN (1996,1998)
GROUP BY YEAR(a.order_date) 
ORDER BY YEAR(a.order_date)
) AS Difference;

-- Which quarter of the year has the highest total sales volume?--
SELECT Quarter(a.order_date) AS quarter, 
Year(a.order_date) AS order_year,
SUM(b.unit_price * b.quantity * (1-b.discount)) AS total_sales
FROM northwind_orders a
JOIN northwind_order_details b
ON a.order_id = b.order_id
GROUP BY quarter, order_year
ORDER BY total_sales DESC
Limit 1;

-- How many repeat customers placed multiple orders across different years?--
SELECT COUNT(*) AS repeat_customers_across_years
FROM (
  SELECT customer_id
  FROM northwind_orders
  GROUP BY customer_id
  HAVING COUNT(DISTINCT YEAR(order_date)) > 1
) AS Repeat_customers; 



