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
