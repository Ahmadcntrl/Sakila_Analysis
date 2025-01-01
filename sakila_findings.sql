-- CREATE TABLE sakila_olap.Fact_rental_payment AS

-- SELECT
-- 	r.rental_id,
--     r.customer_id,
-- 	i.film_id,
--     i.store_id,
--     r.rental_date,
--     r.return_date,
--     p.amount,
--     p.payment_date
-- FROM sakila.rental r
-- join sakila.payment p on p.rental_id=r.rental_id
-- join sakila.inventory i on r.inventory_id=i.inventory_id;


-- DIMENSION_TABLES

-- CREATE TABLE sakila_olap.dim_customer as
-- SELECT 
--     customer_id,
--     first_name,
--     last_name,
--     email,
--     address_id
-- FROM sakila.customer;


-- CREATE TABLE sakila_olap.dim_film as
-- select 
-- 		f.film_id,
--         f.title,
--         f.release_year,
--         c.name as Category
-- from sakila.film f
-- join sakila.film_category fc on fc.film_id=f.film_id
-- join sakila.category c on c.category_id=fc.category_id;      




-- CREATE TABLE sakila_olap.dim_store as
-- select 
-- 	s.store_id,
--     a.address,
--     c.city
-- from sakila.store s
-- join sakila.address a on s.address_id=a.address_id
-- join sakila.city c on a.city_id=c.city_id;
select * from sakila_olap.fact_rental_payment;
select * from sakila_olap.dim_customer;
select * from sakila_olap.dim_film;
select * from sakila_olap.dim_store;

alter table sakila_olap.fact_rental_payment
add primary key (rental_id);
alter table sakila_olap.dim_customer
add primary key (customer_id);
alter table sakila_olap.dim_film
add primary key (film_id);
alter table sakila_olap.dim_store
add primary key (store_id);
alter table sakila_olap.fact_rental_payment
add foreign key (customer_id) references dim_customer(customer_id);
alter table sakila_olap.fact_rental_payment
add foreign key (film_id) references dim_film(film_id);
alter table sakila_olap.fact_rental_payment
add foreign key (store_id) references dim_store(store_id);

show create table sakila_olap.fact_rental_payment;
-----------------------------------------------------------------------------------

-- After creating Fact table and dimension tables and generating ERD-
-- Validating the data model

-----------------------------------------------------------------------------------
-- Purpose
-- Validation ensures that your fact and dimension tables are designed correctly,
--  relationships are properly defined, and the data aligns with your project's goals.
-----------------------------------------------------------------------------------
show create table fact_rental_payment;
show create table dim_customer;
show create table dim_film;
show create table dim_store;
-----------------------------------------------------------------------------------
-- Test Relationships with Sample Joins
-----------------------------------------------------------------------------------
select*from sakila_olap.dim_film;
select*from sakila_olap.dim_customer;
select*from sakila_olap.dim_store;
select concat(first_name,' ',last_name)as Customer_Name from sakila_olap.dim_customer;
select*from sakila_olap.fact_rental_payment;

select 
	f.film_id,
	concat(c.first_name,' ',c.last_name)as Customer_Name,
	fi.title as Film_Name,
	s.city as store_name,
	f.amount
from 
	sakila_olap.fact_rental_payment f
join
	sakila_olap.dim_customer c on f.customer_id=c.customer_id
join
	sakila_olap.dim_film fi on f.film_id=fi.film_id
join
	sakila_olap.dim_store s on f.store_id=s.store_id
    limit 10;
-----------------------------------------------------------------------------------------------------
-- Check Data Integrity

-- Verify that all foreign key columns in the fact table reference valid primary keys in the dimension tables.
-----------------------------------------------------------------------------------------------------    
select customer_id from sakila_olap.dim_customer where customer_id not in(select customer_id from sakila_olap.dim_customer);
select film_id from sakila_olap.dim_film where film_id not in(select film_id from sakila_olap.dim_film);
select store_id from sakila_olap.dim_store where store_id not in(select store_id from sakila_olap.dim_store);
------------------------------------------------------------------------------------------------------
-- Review the ERD 
-- All tables are connected as per the star schema.
-- Fact table relationships to all dimensions are present.
-- Foreign keys visually link the tables.
--  ---------------------------------------------------------------------------------------------------
   -- EDA-Exploratory Data Analysis
   
 --   Identify Business Questions:
 
-- What is the total revenue generated?
-- Which films are the most popular?
-- What are the busiest rental periods?
-- Which customers contribute the most revenue?
-- How do stores perform in terms of revenue and rentals?
---------------------------------------------------------------------------------------------------------
-- Key Performance Indicators (KPIs)
-- Define KPIs that measure business performance:

-- Total Revenue: Sum of all payments.
-- Average Revenue Per Rental: Revenue divided by total rentals.
-- Customer Lifetime Value: Total revenue generated by a customer.
-- Film Popularity: Number of rentals per film.
-- Store Performance: Revenue and rentals by store.
----------------------------------------------------------------------------------------------------------
-- Total Revenue
select * from sakila_olap.fact_rental_payment;
select sum(amount) as Total_revenue from sakila_olap.fact_rental_payment;
-------------------------------------------------------------------
-- total rentals

select count(rental_id) as total_rentals from sakila_olap.fact_rental_payment;
-------------------------------------------------------------------
-- avg revenue per rental

select  avg(amount) as average_revenue_per_rental from sakila_olap.fact_rental_payment;
-------------------------------------------------------------------
-- Top Customers by Revenue

select concat(c.first_name,'  ',c.last_name) as Customer_Name,Sum(f.amount) as Revenue_per_customer from sakila_olap.fact_rental_payment f
join sakila_olap.dim_customer c on f.customer_id=c.customer_id
group by customer_name
order by Revenue_per_customer desc
limit 10;
-------------------------------------------------------------------
-- popular films

select f.film_id,fi.title as film_name,count(f.rental_id) as rental_per_film from sakila_olap.fact_rental_payment f
join sakila_olap.dim_film fi on f.film_id=fi.film_id
group by f.film_id
order by rental_per_film desc
limit 10;

-- rentals by genre
select fi.category,count(f.rental_id) as rental_per_film from sakila_olap.fact_rental_payment f
join sakila_olap.dim_film fi on f.film_id=fi.film_id
group by fi.category
order by rental_per_film desc
limit 10;
--------------------------------------------------------------------
-- total revenue per store

select f.store_id,s.city as store_name,sum(f.amount) as Total_revenue , count(f.rental_id) as Total_rentals from sakila_olap.fact_rental_payment f
join sakila_olap.dim_store s on f.store_id=s.store_id
group by f.store_id
order by total_revenue desc;
--------------------------------------------------------------------
-- Monthly revenue trends
select date_format(f.payment_date,'%Y-%m') as Month,sum(f.amount) as total_revenue from sakila_olap.fact_rental_payment f
group by month
order by month;
-------------------------------------------------------------------

--  Compare Stores: Which store generates the highest revenue?
--  Look at total_revenue to identify the store generating the most revenue.
-- Check total_rentals to see if the high revenue is due to more rentals or higher-paying customers.
-- Use avg_revenue_per_rental to determine whether the difference is due to higher payments per rental.
------------------
-- store 2 generating more revenue as compared to store 1. total rentals of store 2 are more than 1. the avg revenue per rental is less of store 2 from store 1.
------------------
select s.store_id,s.city as store_name,sum(f.amount) as Total_revenue , count(f.rental_id) as Total_rentals,sum(f.amount)/count(f.rental_id) 
as avg_revenue_per_rental from sakila_olap.fact_rental_payment f
join sakila_olap.dim_store s on f.store_id=s.store_id
group by s.store_id
order by total_revenue desc;
-----------------------------------------------------------------------------------------------------------------


-- high frequency of rentals
SELECT 
    concat(c.First_name,' ',c.Last_name) as customer_name, 
    COUNT(f.rental_id) AS total_rentals
FROM sakila_olap.fact_rental_payment f
JOIN sakila_olap.dim_customer c ON f.customer_id = c.customer_id
GROUP BY customer_name
ORDER BY total_rentals DESC
LIMIT 10;
---------------------------------------------------------------------------------------------------------------











