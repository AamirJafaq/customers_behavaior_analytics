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

