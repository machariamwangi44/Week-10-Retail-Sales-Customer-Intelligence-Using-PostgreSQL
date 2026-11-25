--Q1:Retrieve all customer records.
select * from customers;

--Q2: Display customer names, cities, and segments.
select customer_name,city,customer_segment
 from customers;
--Q3:Find customers living in Nairobi.
select * from customers
where city = 'Nairobi';

--Q4:Find customers registered after January 1, 2025.
select * from customers
where registration_date > '2025-01-01'
order by registration_date desc;

--Q5: Display all unique customer cities.
select distinct(city)
from customers;

--Q6: Retrieve the 10 most recent orders.
select * from orders
  order by order_date desc
  limit 10;

--Q7: Find orders with unit prices above KSh 10,000.
select * from orders
 where unit_price > 10000
 order by unit_price desc;

--Q8: Find customers whose names start with A.
select customer_name
from customers
	where customer_name like 'A%';

--Q9:Retrieve orders with quantities between 2 and 5.
select * from orders
	where quantity between 2 and 5;
 

--Q10: Find orders paid through M-Pesa.
select * from orders
	where payment_method ='M-Pesa';

--Q11: Count all customers.
select count(*)
	from customers;

--Q12: Count all orders.
select count(order_id)
from orders;

--Q13: Calculate completed-order revenue.
select round(sum(
           quantity * unit_price * (1 - discount / 100.0)),2)
        as total_revenue
from orders
where order_status = 'Completed';


--Q14: Calculate the average completed-order value.
select round(avg(
           quantity * unit_price * (1 - discount / 100.0)),2)
        as total_revenue
from orders
where order_status = 'Completed';

--Q15: Find the highest and lowest product prices.
select min(unit_price) as lowest_price,
       max(unit_price) as highest_price
from orders;	   

--Q16: Calculate revenue by product category.
select product_category, round(sum(
           quantity * unit_price * (1 - discount / 100.0)),2)
        as total_revenue
from orders
where order_status = 'Completed'
group by product_category
order by total_revenue desc;


--Q17: Count customers by city.
select city, count(*) as customer_count
from customers
group by city;
--Q18:Calculate quantity sold by product.
select product_name, count(quantity) as total_quantity
from orders
group by product_name
order by total_quantity desc;


--Q19:Find categories generating more than KSh 100,000 in revenue.
select *
from (
    select product_category,
           round(sum(quantity * unit_price * (1 - discount / 100)), 2) as total_revenue
    from orders
    where order_status = 'Completed'
    group by product_category
) t
where total_revenue > 100000
order by total_revenue desc;

--Q20: Calculate the percentage of cancelled orders.
select round(
    100.0 * sum(case when order_status = 'Cancelled' then 1 else 0 end) / count(*),
    2
) as cancelled_pct
from orders;

--Q21: Display orders with customer names and cities.
select c.customer_name, c.city, o.*
from customers c
left join orders o on c.customer_id = o.customer_id;
--Q22: Calculate total spending by customer.
select customer_id, sum(quantity * unit_price)
as total_customer_spending
from orders
group by customer_id
order by total_customer_spending desc;

--Q23: Identify customers who have never ordered.
select c.customer_id
from customers c
left join orders o on c.customer_id = o.customer_id
where o.order_id is null;


--Q24: Find the 10 highest-spending customers.
select customer_id, sum(quantity * unit_price)
as total_customer_spending
from orders
group by customer_id
order by total_customer_spending desc
limit 10;

--Q25: Calculate revenue by customer city.
select c.city, round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue_per_city
from orders o
inner join customers c
on o.customer_id = c.customer_id
where order_status = 'Completed'
group by c.city
order by revenue_per_city desc;

--Q26: Identify customers with more than five orders.
select customer_id, count(*) as order_count
from orders
group by customer_id
having count(customer_id) > 5
order by count(customer_id) desc
limit 5;

--Q27:Calculate average customer spending by segment.
select c.customer_segment,
       round(avg(customer_totals.total_spent),2) as avg_customer_spend
from (
    select o.customer_id,
           sum(o.quantity * o.unit_price) as total_spent
    from orders o
    where o.order_status = 'Completed'
    group by o.customer_id
) customer_totals
join customers c
    on customer_totals.customer_id = c.customer_id
group by c.customer_segment;
--Q28: Identify the most popular category among VIP customers
select c.customer_segment, count(quantity)
from orders o
join customers c
on o.customer_id = c.customer_id
where c.customer_segment = 'VIP'
group by c.customer_segment;

--Q29: Find customers spending above the average total spending per purchasing customer.
select c.customer_name
from customers c
join orders o
on c.customer_id = o.customer_id
where order_status = 'Completed'
group by c.customer_name, c.customer_id
having sum(o.quantity * o.unit_price) >
	(select avg(total_customer_spending)
	from
(select sum(quantity * unit_price) as total_customer_spending
from orders
where order_status = 'Completed'
group by customer_id)t
);

--Q30: Find products priced above the overall average unit price.
select product_name
from orders
group by product_name
having avg(unit_price) >
(select round(avg(unit_price),2)
from orders);

--Q31: Use a CTE to identify the three highest-revenue months.
with revenue_per_month as (
	select DATE_TRUNC('month', order_date) as monthly_date,
	round(sum(quantity * unit_price * (1 - discount / 100)),2) as total_revenue
	from orders
	group by monthly_date
	)
select * from revenue_per_month
order by total_revenue desc
limit 3;

--Q32: Find customers purchasing from at least three categories.
with category_purchase as (
	select customer_id, count( distinct product_category) as category_count
	from orders
	group by customer_id
)
select c.customer_name, 
	  cp.category_count
from category_purchase cp
join customers c on
	cp.customer_id = c.customer_id
where category_count >= 3
order by category_count desc;


--Q34: Use a CTE to calculate category revenue, cost, profit, and profit margin.
with category_metrics as (
    select
        product_category,
        round(sum(quantity * unit_price * (1 - discount / 100)), 2) as total_revenue,
        round(sum(quantity * cost_price), 2) as total_cost
    from orders
    group by product_category
)
select
    product_category,
    total_revenue,
    total_cost,
    round(total_revenue - total_cost, 2) as profit,
    round(
        (total_revenue - total_cost) / nullif(total_revenue, 0) * 100,
        2
    ) as profit_margin
from category_metrics
order by profit desc;

--Q34: Find customers whose latest completed order is more than 90 days before the latest order date in the dataset.
with latest_completed_order as (
   select
        customer_id,
        max(order_date) as latest_completed_date
    from orders
    where order_status = 'Completed'
    group by customer_id
)
select
    c.customer_name,
    lco.latest_completed_date
from latest_completed_order lco
join customers c
    on lco.customer_id = c.customer_id
where current_date - lco.latest_completed_date > 90;

--Q35: Rank customers by spending using RANK()
select customer_id, 
sum(quantity * unit_price) as total_spending,
rank() over (order by sum(quantity * unit_price) desc) as rank_customers
from orders
group by customer_id;

--Q36: Number each customer's orders by recency using ROW_NUMBER()
select order_id, customer_id, product_name, product_category,
row_number() over (partition by product_category
order by order_date desc)
from orders;

--Q37: Rank products within categories using DENSE_RANK().
select product_name, product_category,
dense_rank() over (partition by product_category
order by unit_price desc)
from orders;

--Q38: Calculate cumulative monthly revenue.
with monthly_revenue as (
	select DATE_TRUNC('month', order_date) as monthly_date,
	round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue
	from orders
	group by monthly_date
)
select monthly_date,revenue
,sum(revenue) over (order by monthly_date desc) as cumulative_monthly_revenue
from monthly_revenue
order by monthly_date desc;


--Q39: Compare monthly revenue using LAG()

with comparison_monthly_revenue as (
	
	select DATE_TRUNC('month', order_date) as monthly_date,
	round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue
	from orders
	group by monthly_date
)
select monthly_date, revenue,
lag(revenue) over (order by monthly_date desc) as previous_revenue,
revenue - lag(revenue) over (order by monthly_date desc) as revenue_change
from comparison_monthly_revenue
order by monthly_date desc;

--Q40: Calculate month-over-month revenue growth (%).
with comparison_monthly_revenue as (
    select
        DATE_TRUNC('month', order_date) as monthly_date,
        ROUND(sum(quantity * unit_price * (1 - discount / 100)), 2) as revenue
    from orders
    group by monthly_date
)
select
    monthly_date,
    revenue,
    lag(revenue) over (order by monthly_date) as previous_revenue,
    revenue - lag(revenue) over (order by monthly_date) as revenue_change,
    ROUND(
        (
            (revenue - lag(revenue) over (order by monthly_date))
            / lag(revenue) over (order by monthly_date)
        ) * 100,
        2
    ) as mom_growth_pct
from comparison_monthly_revenue
 order by monthly_date;

 --Q41: Divide customers into four spending groups using NTILE(4).

with customer_spending as (
 select
	 customer_id, round(sum(quantity * unit_price * (1 - discount / 100)),2) as total_spending
	 from orders
	 group by customer_id

)
select customer_id,
	total_spending,
	case ntile(4) over (order by total_spending desc)
		when 1 then 'High Value'
		when 2 then 'Upper Mid'
		when 3 then 'Lower mid'
		when 4 then 'Low value'
	end as spending_group
from customer_spending
	order by total_spending desc

--Q42: Calculate each category's share of total revenue using window functions.
With category_revenue as (
    select
        product_category,
        round(
            sum(quantity * unit_price * (1 - discount / 100)),
            2
        ) as revenue
    from orders
    group by product_category
)
select
    product_category,
    revenue,
    round(
        revenue * 100.0 / sum(revenue) over (),
        2
    ) as revenue_share_pct
from category_revenue
order by revenue desc;


--Q43: Create a monthly_sales_summary view (month, orders, revenue, cost, profit), then select from it.
create view monthly_sales_summary as
  select 
	DATE_TRUNC('month', order_date) as monthly_date,
	count(distinct order_id) as orders,
	round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue,
	round(sum(quantity * cost_price),2) as cost,
	round(sum(quantity * unit_price * (1 - discount / 100)),2) - round(sum(quantity * cost_price),2) as profit
	from orders
	group by DATE_TRUNC('month', order_date);
-- select view query
select * from monthly_sales_summary

---Q44: Create a PL/pgSQL function that returns completed-order revenue for a supplied customer ID — show 
		--it for one customer and for an ID that does not exist (it must return 0).

create or replace function get_completed_order_revenue(
    p_customer_id int
)
returns numeric
language plpgsql
as $$
declare
    v_revenue numeric;
begin
    select
        coalesce(
            (sum(quantity * unit_price * (1 - discount / 100)),
            0
        )
    into v_revenue
    from orders
    where customer_id = p_customer_id
      and order_status = 'Completed';

    return v_revenue;
end;
$$;

select get_completed_order_revenue(101);

--Q45: Segment customers into High, Medium and Low Value, and explain why you chose your thresholds.
with customer_spending as (
 select
	 customer_id, round(sum(quantity * unit_price * (1 - discount / 100)),2) as total_spending
	 from orders
	 group by customer_id

)
select customer_id,
	total_spending,
	case ntile(3) over (order by total_spending desc)
		when 1 then 'High Value'
		when 2 then 'Medium Value'
		when 3 then 'Low value'
	end as spending_group
from customer_spending
	order by total_spending desc;
---** I used NTILE(3) to divide customers into three equally sized groups based on total spending. 
       --The top third of customers were classified as High Value, the middle third as Medium Value, and the bottom third as Low Value. 
	   --This approach is objective and data-driven because the thresholds are determined by the distribution of customer spending.


--Q46: Produce a management report: top five customers, top five products, the most profitable category, and the lowest-revenue month.
	-- top 5 customers
	create view top_5_customers as
select
    customer_id,
    round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue
from orders
group by customer_id
order by revenue desc
limit 5;
--top 5 products
create view top_5_products as
select
    product_name,
    round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue
from orders
group by product_name
order by revenue desc
limit 5;
-- most profitable category
create view most_profitable_category as
select
    product_category,
    sum(quantity * unit_price * (1 - discount / 100))
    - sum(quantity * cost_price) as profit
from orders
group by product_category
order by profit desc
limit 1;
-- lowest_revenue_month
create view lowest_revenue_month as
select
    date_trunc('month', order_date) as month,
    round(sum(quantity * unit_price * (1 - discount / 100)),2) as revenue
from orders
group by month
order by revenue
limit 1;

select * from top_5_customers;

select * from top_5_products;

select * from most_profitable_category;

select * from lowest_revenue_month;