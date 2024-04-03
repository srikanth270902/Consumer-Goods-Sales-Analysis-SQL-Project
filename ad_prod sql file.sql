### 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT market FROM gdb023.dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

### 2. What is the percentage of unique product increase in 2021 vs. 2020? The
# final output contains these fields,
# unique_products_2020
# unique_products_2021
# percentage_chg

 Select count(distinct product_code) as unique_prod_2020 from fact_sales_monthly where fiscal_year=2020;
     Select count(distinct product_code)as unique_prod_2021 from fact_sales_monthly where fiscal_year= 2021;
     WITH unique_counts AS (
         SELECT
        (SELECT COUNT(DISTINCT product_code) FROM fact_sales_monthly WHERE fiscal_year = 2020) AS unique_prod_2020,
        (SELECT COUNT(DISTINCT product_code) FROM fact_sales_monthly WHERE fiscal_year = 2021) AS unique_prod_2021
)
SELECT
    unique_prod_2020,
    unique_prod_2021,
    ROUND(((unique_prod_2021 - unique_prod_2020) / unique_prod_2020) * 100, 2) AS percentage_chg
FROM
    unique_counts;
    
    ### 3. Provide a report with all the unique product counts for each segment and
##sort them in descending order of product counts. The final output contains 2 fields,
## segment
### product_count

select segment, count(distinct product) as product_name from dim_product
group by segment 
order by product_name desc ;

### 4. Follow-up: Which segment had the most increase in unique products in
## 2021 vs 2020? The final output contains these fields,
## segment
## product_count_2020
## product_count_2021
## difference

with cte_1 as (
    select count(distinct dim_product.product_code) as prod_code_2020, segment 
    from dim_product
    join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code
    where fact_sales_monthly.fiscal_year = 2020
    group by segment
),
cte_2 as (
    select count(distinct dim_product.product_code) as prod_code_2021, segment
    from dim_product
    join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code
    where fact_sales_monthly.fiscal_year = 2021
    group by segment
)

select cte_1.segment, cte_1.prod_code_2020, cte_2.prod_code_2021,
       (cte_2.prod_code_2021 - cte_1.prod_code_2020) as difference 
from cte_1
join cte_2 on cte_1.segment = cte_2.segment;

### 5. Get the products that have the highest and lowest manufacturing costs.
## The final output should contain these fields,
## product_code
## product
## manufacturing_cost

select max(manufacturing_cost) as max_cost,min(manufacturing_cost) as min_cost,dp.product,fm.product_code from 
fact_manufacturing_cost fm join dim_product dp on dp.product_code =fm.product_code
group by manufacturing_cost,product_code, product
order by product_code asc;

### 6. Generate a report which contains the top 5 customers who received an
## average high pre_invoice_discount_pct for the fiscal year 2021 and in the
## Indian market. The final output contains these fields,
## customer_code
## customer
## average_discount_percentage

select fp.customer_code,fp.pre_invoice_discount_pct as avg_discount_per, dc.customer from 
fact_pre_invoice_deductions fp join dim_customer dc on dc.customer_code=fp.customer_code
where fp.fiscal_year=2021 and dc.market="India"
group by customer_code,customer, pre_invoice_discount_pct
limit 5;

### 7. Get the complete report of the Gross sales amount for the customer “Atliq
## Exclusive” for each month. This analysis helps to get an idea of low and
## high-performing months and take strategic decisions.
## The final report contains these columns:
## Month
## Year
## Gross sales Amount

WITH xxx AS (
   SELECT 
       MONTHNAME(fs.date) AS months,
       YEAR(fs.date) AS years,
       (fg.gross_price * fs.sold_quantity) AS gross_sales_amount,
       fg.product_code
   FROM 
       fact_gross_price fg 
   JOIN 
       fact_sales_monthly fs ON fg.product_code = fs.product_code
   JOIN 
       dim_customer dc ON fs.customer_code = dc.customer_code
   WHERE 
       dc.customer = 'Atliq Exclusive'
)

SELECT 
    months,
    years,
    SUM(gross_sales_amount) AS total_gross_sales_amount 
FROM 
    xxx
GROUP BY 
    months, years
ORDER BY 
    years, months;

### 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
## output contains these fields sorted by the total_sold_quantity,
## Quarter
## total_sold_quantity

SELECT 
 case 
	when month(date) in ( 9,10,11) then "Q1"
    when month(date) in (12,1,2) then "Q2"
    when month(date) in (3,4,5) then "Q3"
    when month(date) in (6,7,8) then "Q4"
    end as Quater,
    round(sum(sold_quantity)/1000000,2) as total_sold_quantity
from fact_sales_monthly
where fiscal_year=2020
group by Quater;

### 9. Which channel helped to bring more gross sales in the fiscal year 2021
## and the percentage of contribution? The final output contains these fields,
## channel
## gross_sales_mln
## percentage

with cte1 as (
select c.channel,
		sum(s.sold_quantity*g.gross_price) as total_sales
from fact_sales_monthly s
join  fact_gross_price g on s.product_code=g.product_code
join  dim_customer c on s.customer_code=c.customer_code
where s.fiscal_year=2021
group by c.channel
)
select 
	channel,
    round(total_sales/100000,2) as gross_sales_mln,
	round((total_sales)/sum(total_sales)over() *100,2) as percentage
from cte1
order by percentage desc;

### 10. Get the Top 3 products in each division that have a high
## total_sold_quantity in the fiscal_year 2021? The final output contains these
## fields,
## division
## product_code

with cte1 as(select
		p.division,
        s.product_code,
        p.product,
        sum(s.sold_quantity) as total_sold_quantity,
        rank() over(partition by division order by sum(s.sold_quantity) desc) as rank_order 
from fact_sales_monthly s
join dim_product p on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.product,division,s.product_code)

select * from cte1
where rank_order in (1,2,3);
