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
	-- compute lifespan in months
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
	-- computing average order revenue
		CASE WHEN total_qty=0 THEN 0 
			ELSE total_sales/total_qty END AS avg_order_revenue,
	-- computing average montly revenue
		CASE WHEN lifespan=0 THEN total_sales ELSE ROUND(total_sales/lifespan) END AS avg_montly_revenue
FROM product_aggregation
);
