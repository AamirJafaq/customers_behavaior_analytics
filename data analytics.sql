-- Creating tables

DROP TABLE IF EXISTS dim_customers;
CREATE TABLE dim_customers(
	customer_key INT,
	customer_id INT,
	customer_number VARCHAR(50),
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	country VARCHAR(50),
	marital_status VARCHAR(50),
	gender VARCHAR(50),
	birthdate DATE,
	create_date DATE
);

DROP TABLE IF EXISTS dim_products;
CREATE TABLE dim_products(
	product_key INT,
	product_id INT,
	product_number VARCHAR(50) ,
	product_name VARCHAR(50) ,
	category_id VARCHAR(50) ,
	category VARCHAR(50) ,
	subcategory VARCHAR(50) ,
	maintenance VARCHAR(50) ,
	cost INT,
	product_line VARCHAR(50),
	start_date DATE 
);
DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales(
	order_number VARCHAR(50),
	product_key INT,
	customer_key INT,
	order_date DATE,
	shipping_date DATE,
	due_date DATE,
	sales_amount INT,
	quantity INT,
	price INT 
);


/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/
CREATE VIEW customers_report AS (
WITH customers_details AS
	(SELECT c.customer_key, c.customer_number,
				CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
				c.country, EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birthdate)) AS age,
				s.order_number, s.product_key, s.order_date, 
				s.sales_amount, s.quantity, s.price
	FROM dim_customers AS c
	LEFT JOIN fact_sales AS s ON c.customer_key=s.customer_key
	WHERE s.order_date IS NOT NULL),
customer_aggregation AS 
(SELECT customer_key, customer_number,  customer_name, country, age,	
			max(order_date) AS last_order_date, 
			-- count total number of orders
			count(DISTINCT order_number) AS total_orders,
			-- count total products purchased by customer
			count(DISTINCT product_key) AS total_products,
			-- compute total sales
			sum(sales_amount) AS total_sales, sum(quantity) AS total_quantity,
			-- comute total lifespan of customer in months
			EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date)))*12
						+EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan
FROM customers_details
GROUP BY 1, 2, 3, 4, 5) 
SELECT customer_key, customer_number, customer_name, country, age,
		CASE
			WHEN age <20 THEN 'Under 20'
			WHEN age BETWEEN 20 AND 29 THEN '20-29'
			WHEN age BETWEEN 30 AND 39 THEN '30-29'
			WHEN age BETWEEN 40 AND 49 THEN '40-49'
			ELSE '50 and above'
			END AS age_group,
		CASE 
			WHEN lifespan >=12 AND total_sales>5000 THEN 'VIP'
			WHEN lifespan >=12 AND total_sales <= 5000 THEN 'Regular'
			ELSE 'New'
			END AS customer_segment, 
			-- compute recency
		EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_order_date))*12+
			EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date)) AS recency_months, 
		-- compute average order value
		CASE WHEN total_orders=0 THEN 0 ELSE total_sales/total_orders END AS avg_order_value,
		-- compute average montly spend
		CASE WHEN lifespan=0 THEN 0 ELSE ROUND(total_sales/lifespan) END AS avg_montly_spend
FROM customer_aggregation
);



/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
CREATE VIEW products_report AS (
WITH product_details AS 
(SELECT s.product_key, p.product_id, p.product_name, p.category,
		p.subcategory, p.cost, s.order_number, s.customer_key, s.order_date, s.sales_amount, s.quantity
FROM fact_sales AS s
LEFT JOIN dim_products AS p ON p.product_key=s.product_key
WHERE s.order_date IS NOT NULL),
product_aggregation AS
(SELECT product_key, product_id, product_name, category, subcategory, cost, 
		max(order_date) AS last_order_date,
		EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date)))*12
						+EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan,
		count(DISTINCT order_number) AS total_orders,
		sum(sales_amount) AS total_sales, 
		sum(quantity) AS total_qty,
		count(DISTINCT customer_key) AS total_customers
FROM product_details
GROUP BY 1,2,3,4,5, 6)
SELECT product_key, product_name, category, subcategory, cost,
		total_customers, total_orders, total_sales, total_qty, lifespan,
		CASE
			WHEN total_sales > 50000 THEN 'High Performer'
			WHEN total_sales >=10000 THEN 'Mid Range'
			ELSE 'Low-Performers'
		END AS product_segment,
		EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_order_date))*12+
			EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date)) AS recency_months,
		CASE WHEN total_qty=0 THEN 0 
			ELSE total_sales/total_qty END AS avg_order_revenue,
		CASE WHEN lifespan=0 THEN total_sales ELSE ROUND(total_sales/lifespan) END AS avg_montly_revenue
FROM product_aggregation);