CREATE DATABASE coffee;
USE coffee;

CREATE TABLE city(
city_id INT PRIMARY KEY,
city_name VARCHAR(50),
population INT,
estimated_rent INT,
city_rank INT
);
ALTER TABLE city
MODIFY COLUMN population BIGINT,
MODIFY COLUMN estimated_rent FLOAT;


CREATE TABLE customers(		
customer_id INT PRIMARY KEY,
customer_name VARCHAR(50),
city_id INT,
CONSTRAINT fk_city FOREIGN KEY(city_id) REFERENCES city(city_id)
);

CREATE TABLE products(
product_id INT PRIMARY KEY,
product_name VARCHAR(50),
price INT
);
ALTER TABLE products
MODIFY COLUMN price FLOAT;

CREATE TABLE sales(
sale_id INT PRIMARY KEY,
sale_date DATE,
product_id INT,
customer_id INT,
total INT,
rating INT,
FOREIGN KEY(product_id) REFERENCES products(product_id),
FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);
ALTER TABLE sales
MODIFY COLUMN total FLOAT;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name AS City,
	ROUND((population * 0.25)/1000000,2) AS Coffee_consumers_in_millions
FROM city
ORDER BY 2 DESC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT sale_date, total,
	YEAR(sale_date) AS year,
	QUARTER(sale_date) AS quarter
FROM sales
WHERE YEAR(sale_date) = 2023 
	AND QUARTER(sale_date) = 4;
    
SELECT SUM(total) AS total_sales
FROM sales
WHERE YEAR(sale_date) = 2023 
	AND QUARTER(sale_date) = 4;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT products.product_name, 
	COUNT(sales.sale_id) AS Units
FROM products
LEFT JOIN sales
ON sales.product_id = products.product_id
GROUP BY products.product_name
ORDER BY 2 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT city.city_name, SUM(sales.total) AS Total_Sale,
	COUNT(DISTINCT customers.customer_id) AS total_customers,
	ROUND(SUM(sales.total)/COUNT(DISTINCT customers.customer_id),2) AS Average_Sale_per_customer
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
GROUP BY 1
ORDER BY 2 DESC;


-- -- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

SELECT city.city_name, city.population,
	ROUND(0.25 * city.population/1000000,2) AS coffee_consumers_in_millions,
	COUNT(DISTINCT customers.customer_id) AS unique_customers
FROM city
JOIN customers ON city.city_id = customers.city_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- -- Q6. Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH top_selling AS
(
SELECT city.city_name, products.product_name,
	COUNT(sales.sale_id) AS count,
	DENSE_RANK() OVER(PARTITION BY city_name ORDER BY COUNT(sales.sale_id) DESC) AS rnk
FROM sales
JOIN products ON sales.product_id = products.product_id
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
GROUP BY 1,2
)
SELECT * 
FROM top_selling
WHERE rnk <=3;


-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT customers.city_id, city.city_name,
	COUNT(DISTINCT sales.customer_id) AS unique_customers
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
WHERE sales.product_id <= 14
GROUP BY 1,2; 


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT customers.city_id, city.city_name, 
	COUNT(DISTINCT sales.customer_id) AS unique_customers, 
	ROUND(SUM(sales.total)/COUNT(DISTINCT sales.customer_id),2) AS Average_sale_per_customer,
	ROUND(city.estimated_rent/COUNT(DISTINCT sales.customer_id),2) AS Average_rent_per_customer
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
GROUP BY 1,2
ORDER BY 5; 


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS
(
	SELECT city.city_name, MONTH(sale_date) AS month, YEAR(sale_date) AS year, SUM(total) AS current_sale
	FROM sales
    JOIN customers ON sales.customer_id = customers.customer_id
    JOIN city ON customers.city_id = city.city_id
	GROUP BY 1, 2, 3
    ORDER BY 1, 3, 2),
last_month AS
(
	SELECT *,
	LAG(current_sale,1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
	FROM monthly_sales
)
SELECT *,
	ROUND(100 * (current_sale - last_month_sale)/last_month_sale,2) AS growth
FROM last_month
WHERE last_month_sale IS NOT NULL;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH total_sale AS (
    SELECT 
        city.city_id,  
        city.city_name, 
        SUM(sales.total) AS total_sales
    FROM sales
    JOIN customers ON sales.customer_id = customers.customer_id
    JOIN city ON customers.city_id = city.city_id
    GROUP BY city.city_id, city.city_name
),
rent AS (
    SELECT 
        total_sale.*, 
        city.estimated_rent
    FROM total_sale
    JOIN city ON total_sale.city_id = city.city_id
),
cust AS(
SELECT rent.*, COUNT(customers.customer_id) AS total_customers
FROM rent
JOIN customers ON rent.city_id = customers.city_id
GROUP BY rent.city_id, rent.city_name
)
SELECT cust.*, 
	ROUND((city.population * 0.25)/1000000,3) AS estimated_consumers_in_millions,
	ROUND(cust.total_sales/cust.total_customers,2) AS average_sale_per_customer,
	ROUND(cust.estimated_rent/cust.total_customers,2) AS average_rent_per_customer
FROM city
JOIN cust ON city.city_id = cust.city_id
ORDER BY 3 DESC,
4 ASC,
5 DESC,
6 DESC,
7 DESC,
8 ASC; 






/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.

