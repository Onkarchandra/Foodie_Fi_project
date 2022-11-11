/* Find number of customer Foodie-Fi ever had */

select count(distinct customer_id) from subscriptions;

/* Find the monthly distribution of trial plan */

select  extract(month from s.start_date) as month_group, 
-- extracting month from start_date
extract(year from s.start_date) as year_group,
-- extracting year from start_date
count(*) as distribution_trialplan
from plans as p inner join subscriptions as s 
on p.plan_id = s.plan_id
where  p.plan_name = 'trial'
group by 1,2
order by  1
;


/* Count of customers taken plan after year 2020*/

select  p.plan_id, p.plan_name, count(*) as num_customer
from plans as p inner join subscriptions as s 
on p.plan_id = s.plan_id
where s.start_date > '2020-12-31'
group by 1,2
order by 1;


/* What is the count and percentage of customers who have churned*/


select count(*) as count_customers, 
round(100*count(*)/
(select count(distinct customer_id) from subscriptions),1) as percentage_churn
from plans as p inner join subscriptions as s
on p.plan_id = s.plan_id
where p.plan_id = 4;

/* Count and percentage of customers who have churned straight 
 after their inital free trial */

with cte as (
select s.customer_id as customer_id,p.plan_id as plan_ids,
p.plan_name,row_number() over(partition by s.customer_id 
order by s.plan_id asc) as order_plan
from plans as p 
inner join subscriptions as s 
on p.plan_id = s.plan_id)

select count(*) as count_customers, 
round(100*count(*)/ 
(select count(distinct customer_id )
from subscriptions),1) as percentage_customers
from cte 
where cte.plan_ids = 4
and cte.order_plan = 2;

/* What is the number and percentage of customer plans after their initial free trial?
*/

with next_plan_cte as (
select customer_id, plan_id, 
lead(plan_id, 1) over( partition by  customer_id 
order by plan_id) as next_plan
from subscriptions)

select 
 next_plan, COUNT(*) as conversions,
 ROUND(100 * COUNT(*)/ (select COUNT(distinct customer_id) 
 from subscriptions),1) as conversion_percentage
from next_plan_cte
where next_plan is not null 
and plan_id = 0
group by  next_plan
order by next_plan;

/*What is the customer count and percentage breakdown for all 5 plans by the end of year 2020*/

with next_plan as (
select 
 customer_id, plan_id, start_date,
 lead(start_date, 1) over(partition by customer_id order by start_date) as next_date
from subscriptions
where start_date <= '2020-12-31'
),
customer_breakdown as (
 select plan_id, 
 COUNT(distinct customer_id) as customers
 from next_plan
 where 
 (next_date is not null and (start_date < '2020-12-31' and next_date > '2020-12-31'))
 or (next_date is null and start_date < '2020-12-31')
 group by plan_id)
select plan_id, customers, 
 ROUND(100 * customers / (select COUNT(distinct customer_id) 
 from subscriptions),1) as percentage
from customer_breakdown
group by  plan_id, customers
order by plan_id;


/*How many customers have upgraded to an annual plan in 2020?*/

select 
 COUNT(distinct customer_id) as unique_customer
from subscriptions
where plan_id = 3
 and start_date <= '2020-12-31';
 
 /*How many days  does it take a customer to upgrade 
 to an annual plan from the day they join Foodie-Fi*/
 
 with trial_plan as 
 (select customer_id, start_date as trial_date
 from subscriptions
 where plan_id = 0
),
annual_plan as
(select customer_id, start_date as annual_date
 from subscriptions
 where plan_id = 3
)
select ap.customer_id,
 datediff(ap.annual_date ,tp.trial_date) as days_to_upgrade
from trial_plan tp
join annual_plan ap
 on tp.customer_id = ap.customer_id
 group by ap.customer_id ;

/*How many customers downgraded from a pro-monthly to a basic monthly plan in 2020?
*/

with next_plan_cte as (
 select customer_id, plan_id, start_date,
 lead(plan_id, 1) over(partition by customer_id order by  plan_id) as next_plan
 from subscriptions)
 select 
COUNT(*) as downgraded
from next_plan_cte
where start_date <= '2020-12-31'
 and plan_id = 2 
 and next_plan = 1;

