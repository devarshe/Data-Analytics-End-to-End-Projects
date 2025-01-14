create database cafe_shop_sales;
use cafe_shop_sales;

select * from cafe_shop_sales;
describe cafe_shop_sales;

SET SQL_SAFE_UPDATES = 0;

UPDATE cafe_shop_sales
set transaction_date = str_to_date(transaction_date,'%d-%m-%Y');

alter table cafe_shop_sales
modify column transaction_date date;

UPDATE cafe_shop_sales
set transaction_time = str_to_date(transaction_time,'%H:%i:%s');

alter table cafe_shop_sales
modify column transaction_time time;

with monthly_sales as (
select 
	round(sum(transaction_qty * unit_price)) as Total_Sales, 
	month(transaction_date) as Month_num,
    monthname(min((transaction_date))) as Month_name
from cafe_shop_sales
group by month(transaction_date)
),
previous_sales as (
select 
	Month_name,
    Month_num,
	Total_Sales,
	lag(Total_Sales,1) over(order by Month_num) as prev_month_sales
from monthly_sales
)
select 
	Total_Sales,
	Month_num,
    Month_name,
    prev_month_sales,
    (Total_Sales - prev_month_sales) as Difference, 
    round((((Total_Sales - prev_month_sales)/prev_month_sales)*100),2) as diff_percent
from previous_sales;

with order_count as (
select 
	count(transaction_id) as Total_Orders, 
    month(transaction_date) as Month_num,
    monthname(min(transaction_date)) as Month_name
from cafe_shop_sales
group by Month_num
), prev_month as(
select 
	lag(Total_Orders,1) over (order by Month_num) as Prev_orders,
    Month_name,
    Month_num,
    Total_Orders
from order_count
)
select 
	Total_Orders,
    Prev_orders,
    Month_name,
    Month_num,
    (Total_Orders - Prev_orders) as Order_growth,
    ((Total_Orders - Prev_orders)/Prev_orders)*100 as Growth_percent
from prev_month;

with sold_quantity as(
select
	sum(transaction_qty) as quantity_sold,
    month(transaction_date) as Month_num,
    monthname(min(transaction_date)) as Month_name
from cafe_shop_sales
group by Month_num
), prev_sold as(
select 
	Month_num,
    Month_name,
    quantity_sold,
    lag(quantity_sold,1) over(order by Month_num) as prev_month_sold
from sold_quantity
)
select
	Month_num,
    Month_name,
    quantity_sold,
    (quantity_sold - prev_month_sold) as growth,
    round((quantity_sold - prev_month_sold)/ prev_month_sold *100,2) as growth_percent
from prev_sold;

select 
	transaction_date,
	concat("$",round(sum(transaction_qty * unit_price),2)) as Total_Sales,
    count(transaction_id) as Total_Orders,
    round(sum(transaction_qty),2) as Total_quantity_sold
from cafe_shop_sales
group by transaction_date;

select 
	transaction_date,
	concat("$",round(sum(transaction_qty * unit_price),2)) as Total_Sales,
    count(transaction_id) as Total_Orders,
    round(sum(transaction_qty),2) as Total_quantity_sold
from cafe_shop_sales
-- where transaction_date = " "			for pinpoint analysis
group by transaction_date;

select 
	"Weekend Stats"as Row_headings,
	concat("$",round(sum(transaction_qty * unit_price),2)) as Total_Sales,
    count(transaction_id) as Total_Orders,
    round(sum(transaction_qty),2) as Total_quantity_sold
from cafe_shop_sales
where dayname(transaction_date) in ("Sunday","Saturday")
union 
select 
	"Weekday Stats" ,
	concat("$",round(sum(transaction_qty * unit_price),2)) as Total_Sales,
    count(transaction_id) as Total_Orders,
    round(sum(transaction_qty),2) as Total_quantity_sold
from cafe_shop_sales
where dayname(transaction_date) not in ("Sunday","Saturday");

select 
	case
		when dayname(transaction_date) in ("Sunday","Saturday") then "Weekend"
        else "Weekday"
	end as Day_type,
    concat("$",round(avg(total_sales),2)) as Avg_Sales
from(
		select 
        transaction_date,
        sum(transaction_qty * unit_price) as total_sales
        from cafe_shop_sales 
        group by transaction_date) as inner_query
group by Day_type;

update cafe_shop_sales
set store_location = "Boston"
where store_location = "Hell's Kitchen";  -- making the changes in the location name instead of cafe name

select 
	store_location,
    concat("$ ", round(sum(transaction_qty*unit_price))) as Total_Sales,
    count(transaction_id) as Total_Orders,
    sum(transaction_qty) as Total_quantity_sold
from cafe_shop_sales
group by store_location;

with monthly_sales as (
select 
	store_location,
	round(sum(transaction_qty * unit_price)) as Total_Sales, 
	month(transaction_date) as Month_num,
    monthname(min((transaction_date))) as Month_name
from cafe_shop_sales
group by store_location, month(transaction_date)
),
previous_sales as (
select 
	store_location,
	Month_name,
    Month_num,
	Total_Sales,
	lag(Total_Sales,1) over(partition by store_location order by Month_num) as prev_month_sales
from monthly_sales
), difference_sales as(
select 
	store_location,
	Total_Sales,
	Month_num,
    Month_name,
    prev_month_sales,
    (Total_Sales - prev_month_sales) as Difference, 
    round((((Total_Sales - prev_month_sales)/prev_month_sales)*100),2) as diff_percent
from previous_sales
)
select 
	store_location,
	Month_name,
    Month_num,
    Total_Sales,
    prev_month_sales,
    Difference,
    diff_percent
from difference_sales
ORDER BY Month_num;


select avg(average) as avg_sales
from (
		select sum(unit_price * transaction_qty) as average
        from cafe_shop_sales
        where month(transaction_date) = 5
        group by transaction_date
        ) as innerquery;

with month_track as (
	select 	
		  sum(transaction_qty*unit_price) as Sales,
		  (transaction_date) as dates,
          month(transaction_date) as month_num,
          monthname(min(transaction_date)) as month_name
	from cafe_shop_sales
    group by transaction_date
)
select 
		month_num,
		month_name,
        dates,
        Round(Sales,2)as Sales_daily,
        Round(avg(sales) over( partition by month_name),2) as Avg_sales,
        case
			when Round(Sales,2) > Round(avg(sales) over( partition by month_name),2) then "Above Average"
            else "Below Average"
		end as Result
from month_track
order by month_num;

select 
	product_category,
    sum(transaction_qty * unit_price) as sales
from cafe_shop_sales
group by product_category
order by sales desc;

select 
	product_type,
    sum(transaction_qty * unit_price) as sales
from cafe_shop_sales
where product_category = (
							select 
									product_category
							from cafe_shop_sales
							group by product_category
							order by sum(transaction_qty * unit_price) desc
                            limit 1)
group by product_type
order by sales desc;

select 
	product_type,
    product_category,
    sum(transaction_qty * unit_price) as sales
from cafe_shop_sales
group by product_type,product_category
order by sales desc
limit 10;

select 
		dayofweek(transaction_date) as day_number,
        case 
			when dayofweek(transaction_date) = 1 then 'Sunday'
            when dayofweek(transaction_date) = 2 then 'Monday'
            when dayofweek(transaction_date) = 3 then 'Tuesday'
            when dayofweek(transaction_date) = 4 then 'Wednesday'
            when dayofweek(transaction_date) = 5 then 'Thursday'
            when dayofweek(transaction_date) = 6 then 'Friday'
            else 'Saturday'
            end as Day_of_week,
        sum(transaction_qty * unit_price) as sales
from cafe_shop_sales
group by day_number,Day_of_week
order by sales desc;

select 
	hour(transaction_time) as Hours,
    round(sum(transaction_qty * unit_price),2) as sales
from cafe_shop_sales
group by Hours
order by Hours;

select 
    hour(transaction_time) as Hours,
     case 
			when dayofweek(transaction_date) = 1 then 'Sunday'
            when dayofweek(transaction_date) = 2 then 'Monday'
            when dayofweek(transaction_date) = 3 then 'Tuesday'
            when dayofweek(transaction_date) = 4 then 'Wednesday'
            when dayofweek(transaction_date) = 5 then 'Thursday'
            when dayofweek(transaction_date) = 6 then 'Friday'
            else 'Saturday'
	end as Day_of_week,
    round(sum(transaction_qty * unit_price),2) as sales
from cafe_shop_sales
group by Hours,dayofweek(transaction_date),Day_of_week
order by Hours,dayofweek(transaction_date);

select 
    hour(transaction_time) as Hours,
     case 
			when dayofweek(transaction_date) = 1 then 'Sunday'
            when dayofweek(transaction_date) = 2 then 'Monday'
            when dayofweek(transaction_date) = 3 then 'Tuesday'
            when dayofweek(transaction_date) = 4 then 'Wednesday'
            when dayofweek(transaction_date) = 5 then 'Thursday'
            when dayofweek(transaction_date) = 6 then 'Friday'
            else 'Saturday'
	end as Day_of_week,
    round(sum(transaction_qty * unit_price),2) as sales,
    count(*) as Orders,
    sum(transaction_qty) as Sold_items
from cafe_shop_sales
where month(transaction_date) = 2 								 -- MONTH SELECTION (in this case it is 2 / February)
group by Hours,dayofweek(transaction_date),Day_of_week
order by Hours,dayofweek(transaction_date);

select dayofweek(transaction_date), transaction_date, dayname(transaction_date)
from cafe_shop_sales
group by transaction_date
