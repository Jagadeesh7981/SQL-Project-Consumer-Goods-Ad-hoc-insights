/*Task 1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region*/

SELECT DISTINCT market
FROM dim_customer
WHERE customer="Atliq Exclusive" AND region="APAC";

------------------------------------------------------
/*Task 2 What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg*/

WITH Cte1 AS
(
 SELECT COUNT(DISTINCT product_code) AS unique_product_2020
 FROM fact_sales_monthly
 WHERE fiscal_year="2020"
 ),
 cte2 AS(
 SELECT COUNT(DISTINCT product_code) AS unique_product_2021
 FROM fact_sales_monthly
 WHERE fiscal_year="2021"
 )
 
 SELECT
 c1.unique_product_2020,c2.unique_product_2021,
 round((c2.unique_product_2021-c1.unique_product_2020)*100/c1.unique_product_2020,2) AS Percentage_chg
 FROM cte1 c1
 JOIN cte2 c2

------------------------------------------------------------------
/*Task 3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
The final output contains 2 fields, segment product_count*/

SELECT segment , COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

----------------------------------------------------------------

/*Task 4 Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
The final output contains these fields, segment product_count_2020 product_count_2021 difference*/

with cte1 as
(
SELECT p.segment,count(distinct s.product_code) as product_count_2020
from fact_sales_monthly s
join dim_product p
using(product_code)
where s.fiscal_year="2020"
group by p.segment
),
cte2 as(
SELECT p.segment,count(distinct s.product_code) as product_count_2021
from fact_sales_monthly s
join dim_product p
using(product_code)
where s.fiscal_year="2021"
group by p.segment
)

SELECT c1.segment,product_count_2020,product_count_2021,(product_count_2021-product_count_2020) as Difference
From cte1 c1
JOin cte2 c2
on c1.segment=c2.segment
order by  Difference desc

-------------------------------------------------------------
/*Task 5 Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields, product_code product manufacturing_cost*/

SELECT
    m.product_code,
    p.product,
    m.manufacturing_cost
FROM dim_product p
join fact_manufacturing_cost m
using(product_code)
WHERE
    manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
    or manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
order by manufacturing_cost desc


------------------------------------------------------------------
/*Task 6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
The final output contains these fields, customer_code customer average_discount_percentage 7.*/



 SELECT pre.customer_code,c.customer, round( AVG (pre_invoice_discount_pct)*100,2) as Avg_Discount_Pct
 from fact_pre_invoice_deductions pre
 join dim_customer c
 using(customer_code)
 where pre.fiscal_year="2021" and c.market="INDIA"
 group by c.customer,pre.customer_code
 order by Avg_discount_pct desc
 limit 5
 
 -------------------------------------------------------------
 /*Task 7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month .
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month Year Gross sales Amount*/
 
 SELECT CONCAT(MONTHNAME(s.date), ' (', YEAR(s.date), ')') as Month,s.fiscal_year as Year,
 Concat(round(sum((g.gross_price*s.sold_quantity))/1000000,2),'M') as Gross_Sales_Amount
 from fact_gross_price g
 join fact_sales_monthly s
 using(product_code,fiscal_year)
 join dim_customer c
 using(customer_code)
 where c.customer="Atliq Exclusive"
 group by s.date, s.fiscal_year
 Order by Year
 -----------------------------------------------------------------
/*Task 8 In which quarter of 2020, got the maximum total_sold_quantity?
The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity*/
 
SELECT
case
when month(date) in (9,10,11) then "Q1"
when month(date) in (12,1,2) then "Q2"
when month(date) in (3,4,5) then "Q3"
when month(date) in (6,7,8) then "Q4"
end as Quarters, Concat(Round(sum(sold_quantity)/1000000,2),'M') as Total_sold_quantity_mln
from fact_sales_monthly 
where fiscal_year=2020
group by Quarters

-----------------------------------------------------------------------------
/*Task 9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
The final output contains these fields, channel gross_sales_mln percentage 10.*/
 
 WITH cte1 AS (
    SELECT
        c.channel,
        ROUND(SUM((g.gross_price * s.sold_quantity)) / 1000000, 2) AS Gross_Sales_Mln
    FROM
        fact_gross_price g
    JOIN
        fact_sales_monthly s USING (product_code,fiscal_year)
    JOIN
        dim_customer c USING (customer_code)
    GROUP BY
        c.channel
)
SELECT
    channel, Concat(Gross_Sales_Mln,'M') AS Gross_Sales_Mln,
Concat(ROUND((Gross_Sales_Mln / SUM(Gross_Sales_Mln) OVER ()) * 100, 2),'%')  AS Percentage_Contribution
FROM
    cte1
ORDER BY Gross_Sales_Mln
--------------------------------------------------------------------------------------------------------------------------------------------
/*Task 10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
The final output contains these fields, division ,product_code,product ,total_sold_quantity, rank_order*/


with cte1 as
(
SELECT p.division,s.product_code,p.product,sum(sold_quantity) as Total_sold_quantity

From fact_sales_monthly s
join dim_product p
using(product_code)
where s.fiscal_year="2021"
group by p.division,s.product_code,p.product
),
cte2 as(
SELECT *,rank() over(partition by division order by Total_sold_quantity desc) AS rnk
From cte1)
Select *
From Cte2
where rnk<=3
