# 📦 E-Commerce Database Optimization & Design

This project demonstrates how I designed and optimized an e-commerce database using PostgreSQL.

I worked with **10,000+ records** to simulate a real-world system, improved query performance, and ensured data consistency using proper database design and optimization techniques.

---

## 🛠️ Tech Stack

- PostgreSQL  
- SQL (Advanced Queries, CTEs, Window Functions)  
- pgAdmin  

---

## 🛠️ System Architecture & Database Design

The database follows a **star schema design** with a central fact table (`sales`) connected to dimension tables (`customers`, `products`, and `city`).

```text
                +------------------+
                |      city        |
                +------------------+
                | PK | city_id     |
                +----+-------------+
                       |
                       | 1
                       |
                       | N
                +----------------------+
                |      customers       |
                +----------------------+
                | PK | customer_id     |
                | FK | city_id         |
                +----+-----------------+
                       |
                       | 1
                       |
                       | N
        +-------------------------------------+
        |              sales                  |
        +-------------------------------------+
        | PK | sale_id                        |
        | FK | customer_id                   |
        | FK | product_id                    |
        +----+--------------------------------+
                       |
                       | N
                       |
                       | 1
                +-----------------------+
                |       products        |
                +-----------------------+
                | PK | product_id       |
                +----+------------------+
```

### 📌 Relationship Summary
- One **city → many customers**
- One **customer → many sales**
- One **product → many sales**

This design ensures:
- Efficient querying  
- Reduced redundancy  
- Scalable analytics  

---

### Key Design Features:
- Primary Keys & Foreign Keys  
- Data validation using `CHECK` constraints  
- Referential integrity (`ON DELETE RESTRICT`)  
- Automatic timestamps (`created_at`)  

---

## ⚡ Performance Optimization

### Before Optimization:
- Queries used **Sequential Scans** (slow)

### Improvements:
- Created indexes:
  - `sales(customer_id)`
  - `sales(product_id)`
  - `customers(city_id)`

### After Optimization:
- Queries switched to **Index Scans**
- Faster joins using optimized execution plans  
- Execution time reduced to ~**16 ms**

---

## 📊 Business Analytics Queries

This project includes real-world analytics queries such as:

- Revenue analysis (quarterly performance)
- Customer segmentation  
- Product demand analysis  
- Market penetration  
- Top products per city  
- Month-over-month growth  

### Advanced SQL Used:
- `JOIN`
- `GROUP BY`
- `CTE (WITH)`
- `DENSE_RANK()`
- `LAG()` (window function)

---

## 🔒 Data Safety (ACID Transactions)

```sql
BEGIN;

UPDATE public.products 
SET price = price * 0.9 
WHERE product_id = 1;

UPDATE public.products 
SET price = -150.00 
WHERE product_id = 2;

COMMIT;
```

### Result:
- Invalid update is rejected due to constraints  
- Transaction is rolled back  
- Data remains consistent  

---

## ▶️ How to Run This Project

1. Create database in PostgreSQL  
2. Run the SQL script to create tables  
3. Import CSV data in this order:
   - city → products → customers → sales  
4. Run queries from Phase 2 & Phase 3  

---

## 🎯 Skills Demonstrated

- Database Design (Star Schema)  
- SQL Optimization & Indexing  
- Performance Tuning (`EXPLAIN ANALYZE`)  
- Advanced SQL (CTE, Window Functions)  
- Data Integrity & Constraints  
- Real-world Business Analysis  

---

## 🚀 Conclusion

This project shows how to transform a basic database into a **high-performance, scalable, and reliable system** using proper database engineering techniques.
