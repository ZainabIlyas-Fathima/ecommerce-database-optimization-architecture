


-- ====================================================================
-- PROJECT: E-Commerce Database Optimization & Schema Design Architecture
-- ARCHITECT: Data Engineering & DBA Case Study
-- ====================================================================

-- ====================================================================
-- PHASE 1: ENTERPRISE SCHEMA ENFORCEMENT & DDL
-- ====================================================================

-- Safe Cleanup of Existing Structures
DROP TABLE IF EXISTS public.sales CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.city CASCADE;

-- 1. City Dimension Table
CREATE TABLE public.city (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL UNIQUE, 
    population BIGINT CHECK (population >= 0), 
    estimated_rent FLOAT CHECK (estimated_rent >= 0),
    city_rank INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

-- 2.Products Dimension Table
CREATE TABLE public.products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50) NOT NULL,
    price FLOAT NOT NULL CHECK (price >= 0), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Customers Dimension Table
CREATE TABLE public.customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50) NOT NULL,
    city_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES public.city(city_id) ON DELETE RESTRICT
);

-- 4. Sales Fact Table
CREATE TABLE public.sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE NOT NULL,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    total FLOAT NOT NULL CHECK (total >= 0),
    rating INT CHECK (rating BETWEEN 1 AND 5), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id) ON DELETE RESTRICT
);

-- ====================================================================
-- CRITICAL ACTION REQUIRED: CSV IMPORT PIPELINE
-- ====================================================================
-- Before proceeding, right-click each table in pgAdmin and import CSVs in this order:
--   1. city -> 2. products -> 3. customers -> 4. sales
-- IMPORTANT DBA STEP: In the "Columns" tab of the pgAdmin import tool, 
-- UNCHECK the 'created_at' column so the engine auto-generates the audit timestamps.

-- ====================================================================
-- POST-IMPORT SCHEMA VERIFICATION
-- ====================================================================

SELECT * FROM public.city;
SELECT * FROM public.products;
SELECT * FROM public.customers;
SELECT * FROM public.sales;


-- ====================================================================
-- PHASE 2: CORE BUSINESS INTELLIGENCE WORKLOAD
-- ====================================================================

-- Q.1 Target Market Consumer Density Analysis
SELECT 
	city_name,
	ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
	city_rank
FROM public.city
ORDER BY 2 DESC;

-- Q.2 Revenue Aggregation (Q4 2023 Performance metrics)
SELECT 
	SUM(total) as total_revenue
FROM public.sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023
	AND EXTRACT(quarter FROM sale_date) = 4;

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM public.sales as s
JOIN public.customers as c ON s.customer_id = c.customer_id
JOIN public.city as ci ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3 Product Sales Volume Distribution
SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM public.products as p
LEFT JOIN public.sales as s ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.4 Average Ticket Size per Customer by Region
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_pr_cx
FROM public.sales as s
JOIN public.customers as c ON s.customer_id = c.customer_id
JOIN public.city as ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.5 Market Penetration Profile (Estimated vs Active Users)
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM public.city
),
customers_table AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM public.sales as s
	JOIN public.customers as c ON c.customer_id = s.customer_id
	JOIN public.city as ci ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN customers_table ON city_table.city_name = customers_table.city_name;

-- Q.6 Regional Product Velocity (Top 3 Items per City)
SELECT * 
FROM (
	SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rank
	FROM public.sales as s
	JOIN public.products as p ON s.product_id = p.product_id
	JOIN public.customers as c ON c.customer_id = s.customer_id
	JOIN public.city as ci ON ci.city_id = c.city_id
	GROUP BY 1, 2
) as t1
WHERE rank <= 3;

-- Q.7 Customer Segmentation (Total Active Core Coffee Buyers)
SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM public.city as ci
LEFT JOIN public.customers as c ON c.city_id = ci.city_id
JOIN public.sales as s ON s.customer_id = c.customer_id
WHERE 
	s.product_id <= 14  -- Optimized via sequential evaluation constraint
GROUP BY 1;

-- Q.8 Operational Efficiency Index (Average Sales Revenue vs Base Rent)
WITH city_table AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_pr_cx
	FROM public.sales as s
	JOIN public.customers as c ON s.customer_id = c.customer_id
	JOIN public.city as ci ON ci.city_id = c.city_id
	GROUP BY 1
),
city_rent AS
(
	SELECT city_name, estimated_rent FROM public.city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent::numeric / ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

-- Q.9 Month-over-Month (MoM) Regional Sales Velocity Growth
WITH monthly_sales AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as year,
		SUM(s.total) as total_sale
	FROM public.sales as s
	JOIN public.customers as c ON c.customer_id = s.customer_id
	JOIN public.city as ci ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
),
growth_ratio AS
(
	SELECT
		city_name,
		month,
		year,
		total_sale as cr_month_sale,
		LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
	FROM monthly_sales
)
SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND((cr_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100, 2) as growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;	

-- Q.10 Comprehensive Market Potential Assessment Model
WITH business_duration AS (
    -- Determines operational runtime scope across data timeline
    SELECT COUNT(DISTINCT TEXT(EXTRACT(YEAR FROM sale_date)) || '-' || TEXT(EXTRACT(MONTH FROM sale_date)))::numeric as total_months
    FROM public.sales
),
city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) as total_revenue,
        COUNT(DISTINCT s.customer_id) as total_cx,
        ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as avg_sale_pr_cx
    FROM public.sales as s
    JOIN public.customers as c ON s.customer_id = c.customer_id
    JOIN public.city as ci ON ci.city_id = c.city_id
    GROUP BY 1
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND(population * 0.25) as estimated_coffee_consumers -- Displaying absolute volume scale
    FROM public.city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    (cr.estimated_rent * bd.total_months) as true_total_rent, -- Normalized cost structures
    ct.total_cx,
    cr.estimated_coffee_consumers, 
    ct.avg_sale_pr_cx,
    ROUND((cr.estimated_rent * bd.total_months)::numeric / ct.total_cx::numeric, 2) as true_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct ON cr.city_name = ct.city_name
CROSS JOIN business_duration as bd
ORDER BY total_revenue DESC;


-- ====================================================================
-- PHASE 3: DATABASE ADMINISTRATION & PERFORMANCE EXPERIMENTS
-- ====================================================================

-- 1. Baseline System Profiling (Before Optimization Work)
-- Execute this block and review the 'Sequential Scan' data operators in your plan log.
EXPLAIN (ANALYZE, BUFFERS)
SELECT ci.city_name, p.product_name, COUNT(s.sale_id) as total_orders
FROM public.sales as s
JOIN public.products as p ON s.product_id = p.product_id
JOIN public.customers as c ON c.customer_id = s.customer_id
JOIN public.city as ci ON ci.city_id = c.city_id
GROUP BY 1, 2;

-- 2. Engineering Targeted Performance Indexes
CREATE INDEX idx_sales_customer_id ON public.sales(customer_id);
CREATE INDEX idx_sales_product_id ON public.sales(product_id);
CREATE INDEX idx_customers_city_id ON public.customers(city_id);

-- 3. Post-Optimization Profiling (Performance Victory Check)
-- Execute again to verify structural transition from Sequential Scan to high-speed Index Scans.
EXPLAIN (ANALYZE, BUFFERS)
SELECT ci.city_name, p.product_name, COUNT(s.sale_id) as total_orders
FROM public.sales as s
JOIN public.products as p ON s.product_id = p.product_id
JOIN public.customers as c ON c.customer_id = s.customer_id
JOIN public.city as ci ON ci.city_id = c.city_id
GROUP BY 1, 2;

-- 4. ACID Transaction Safety & Constraint Verification
BEGIN;

-- Operation A: Valid transaction update succeeds safely
UPDATE public.products SET price = price * 0.9 WHERE product_id = 1;

-- Operation B: Malformed price injection blocks execution via Phase 1 CHECK rule
UPDATE public.products SET price = -150.00 WHERE product_id = 2;

-- Engine will explicitly prevent compilation here due to standard state violations
COMMIT;

-- Reverts the engine environment to safe baseline conditions cleanly
ROLLBACK;