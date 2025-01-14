-- Create the database and use it
CREATE DATABASE cafe_shopdb;
GO
USE cafe_shopdb;
GO

-- View the table and its structure
SELECT * FROM cafe_shop_sales;
EXEC sp_help 'cafe_shop_sales'; -- Equivalent to DESCRIBE

-- Allow updates
SET NOCOUNT ON; -- Suppresses messages about rows affected


-- Update transaction_date and change its data type
UPDATE cafe_shop_sales
SET transaction_date = CONVERT(date, transaction_date, 103); -- Format 103 for 'dd/mm/yyyy'

ALTER TABLE cafe_shop_sales
ALTER COLUMN transaction_date DATE;

-- Update transaction_time and change its data type
UPDATE cafe_shop_sales
SET transaction_time = CONVERT(time, transaction_time, 108); -- Format 108 for 'HH:MM:SS'

ALTER TABLE cafe_shop_sales
ALTER COLUMN transaction_time TIME;

-- Aggregate queries
SELECT concat('$',SUM(unit_price * transaction_qty)) AS Total_Sales
FROM cafe_shop_sales;

SELECT COUNT(*) AS Total_Transactions
FROM cafe_shop_sales;

select sum(transaction_qty) as TOTAL_QUANTITY_SOLD
from cafe_shop_sales;

-- Monthly Sales Analysis
WITH monthly_sales AS (
    SELECT 
        ROUND(SUM(transaction_qty * unit_price), 2) AS Total_Sales,
        MONTH(transaction_date) AS Month_num,
        DATENAME(MONTH, MIN(transaction_date)) AS Month_name
    FROM cafe_shop_sales
    GROUP BY MONTH(transaction_date)
),
previous_sales AS (
    SELECT 
        Month_name,
        Month_num,
        Total_Sales,
        LAG(Total_Sales) OVER (ORDER BY Month_num) AS prev_month_sales
    FROM monthly_sales
)
SELECT 
    Month_num,
    Month_name,
    Total_Sales,
    prev_month_sales,
    (Total_Sales - prev_month_sales) AS Difference,
    ROUND(((Total_Sales - prev_month_sales) * 100.0 / prev_month_sales), 2) AS diff_percent
FROM previous_sales;

-- Order Count and Growth Analysis
WITH order_count AS (
    SELECT 
        COUNT(transaction_id) AS Total_Orders,
        MONTH(transaction_date) AS Month_num,
        DATENAME(MONTH, MIN(transaction_date)) AS Month_name
    FROM cafe_shop_sales
    GROUP BY MONTH(transaction_date)
),
prev_month AS (
    SELECT 
        LAG(Total_Orders) OVER (ORDER BY Month_num) AS Prev_orders,
        Month_name,
        Month_num,
        Total_Orders
    FROM order_count
)
SELECT 
    Month_num,
	Month_name,
	Total_Orders,
	Prev_orders,
    (Total_Orders - Prev_orders) AS Order_growth,
    FORMAT(((Total_Orders - Prev_orders) * 100.00 / Prev_orders), 'N2') AS Growth_percent
FROM prev_month;

-- Quantity Sold Analysis
WITH sold_quantity AS (
    SELECT 
        SUM(transaction_qty) AS quantity_sold,
        MONTH(transaction_date) AS Month_num,
        DATENAME(MONTH, MIN(transaction_date)) AS Month_name
    FROM cafe_shop_sales
    GROUP BY MONTH(transaction_date)
),
prev_sold AS (
    SELECT 
        Month_num,
        Month_name,
        quantity_sold,
        LAG(quantity_sold) OVER (ORDER BY Month_num) AS prev_month_sold
    FROM sold_quantity
)
SELECT 
    Month_num,
    Month_name,
    quantity_sold,
    prev_month_sold,
    (quantity_sold - prev_month_sold) AS growth,
    Format((quantity_sold - prev_month_sold) * 100.0 / prev_month_sold, 'N2') AS growth_percent
FROM prev_sold;

-- Daily Sales Summary
SELECT 
    transaction_date,
    CONCAT('$', ROUND(SUM(transaction_qty * unit_price), 2)) AS Total_Sales,
    COUNT(transaction_id) AS Total_Orders,
    ROUND(SUM(transaction_qty), 2) AS Total_quantity_sold
FROM cafe_shop_sales
GROUP BY transaction_date
ORDER BY transaction_date ;

-- Daily Sales for a Specific Month
SELECT 
    transaction_date,
    CONCAT('$', ROUND(SUM(transaction_qty * unit_price), 2)) AS Total_Sales,
    COUNT(transaction_id) AS Total_Orders,
    ROUND(SUM(transaction_qty), 2) AS Total_quantity_sold
FROM cafe_shop_sales
WHERE MONTH(transaction_date) = 5 -- Example: May
GROUP BY transaction_date
ORDER BY transaction_date;

-- Weekday v/s Weekend 
SELECT 
    'Weekend Stats' AS Row_headings,
    CONCAT('$', ROUND(SUM(transaction_qty * unit_price), 2)) AS Total_Sales,
    COUNT(transaction_id) AS Total_Orders,
    ROUND(SUM(transaction_qty), 2) AS Total_quantity_sold
FROM cafe_shop_sales
WHERE DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday')
UNION
SELECT 
    'Weekday Stats' AS Row_headings,
    CONCAT('$', ROUND(SUM(transaction_qty * unit_price), 2)) AS Total_Sales,
    COUNT(transaction_id) AS Total_Orders,
    ROUND(SUM(transaction_qty), 2) AS Total_quantity_sold
FROM cafe_shop_sales
WHERE DATENAME(WEEKDAY, transaction_date) NOT IN ('Saturday', 'Sunday');

-- Weekend vs Weekday Avg Sales comparision
SELECT 
    CASE 
        WHEN DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_type,
    CONCAT('$', ROUND(AVG(total_sales), 2)) AS Avg_Sales
FROM (
    SELECT 
        transaction_date,
        SUM(transaction_qty * unit_price) AS total_sales
    FROM cafe_shop_sales
    GROUP BY transaction_date
) AS inner_query
GROUP BY 
    CASE 
        WHEN DATENAME(WEEKDAY, transaction_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END;

-- Update Store Location
UPDATE cafe_shop_sales
SET store_location = 'Boston'
WHERE store_location = 'Astoria';

UPDATE cafe_shop_sales
SET store_location = 'Washington'
WHERE store_location = 'Lower Manhattan';

UPDATE cafe_shop_sales
SET store_location = 'New York'
WHERE store_location = 'Hell''s Kitchen';

-- Location-Wise Sales
SELECT 
    store_location,
    CONCAT('$', ROUND(SUM(transaction_qty * unit_price), 2)) AS Total_Sales,
    COUNT(transaction_id) AS Total_Orders,
    SUM(transaction_qty) AS Total_quantity_sold
FROM cafe_shop_sales
GROUP BY store_location;

-- Location-Wise Monthly Sales Growth
WITH monthly_sales AS (
    SELECT 
        store_location,
        ROUND(SUM(transaction_qty * unit_price), 2) AS Total_Sales,
        MONTH(transaction_date) AS Month_num,
        DATENAME(MONTH, MIN(transaction_date)) AS Month_name
    FROM cafe_shop_sales
    GROUP BY store_location, MONTH(transaction_date)
),
previous_sales AS (
    SELECT 
        store_location,
        Month_name,
        Month_num,
        Total_Sales,
        LAG(Total_Sales) OVER (PARTITION BY store_location ORDER BY Month_num) AS prev_month_sales
    FROM monthly_sales
)
SELECT 
    store_location,
    Month_name,
    Month_num,
    Total_Sales,
    prev_month_sales,
    (Total_Sales - prev_month_sales) AS Difference,
    ROUND(((Total_Sales - prev_month_sales) * 100.0 / prev_month_sales), 2) AS diff_percent
FROM previous_sales
ORDER BY Month_num;

-- Average Sales per day
SELECT AVG(average) AS avg_sales
FROM (
    SELECT SUM(unit_price * transaction_qty) AS average
    FROM cafe_shop_sales
    -- WHERE MONTH(transaction_date) = 5 #if you need to do month specific average
    GROUP BY transaction_date, 
) AS innerquery;

-- Daily Average in every month
WITH daily_sales AS (
    SELECT 
        MONTH(transaction_date) AS month_num,
        DATENAME(MONTH, transaction_date) AS month_name,
        transaction_date,
        SUM(unit_price * transaction_qty) AS daily_sales
    FROM cafe_shop_sales
    GROUP BY MONTH(transaction_date), DATENAME(MONTH, transaction_date), transaction_date
),
monthly_avg_sales AS (
    SELECT 
        month_num,
        month_name,
        AVG(daily_sales) AS avg_daily_sales
    FROM daily_sales
    GROUP BY month_num, month_name
)
SELECT 
    month_num,
    month_name,
    ROUND(avg_daily_sales, 2) AS avg_daily_sales
FROM monthly_avg_sales
ORDER BY month_num;

-- Monthly Sales Analysis with Above/Below Average
WITH month_track AS (
    SELECT 
        SUM(transaction_qty * unit_price) AS Sales,
        transaction_date AS dates,
        MONTH(transaction_date) AS month_num,
        DATENAME(MONTH, MIN(transaction_date)) AS month_name
    FROM cafe_shop_sales
    GROUP BY transaction_date
)
SELECT 
    month_num,
    month_name,
    dates,
    ROUND(Sales, 2) AS Sales_daily,
    ROUND(AVG(Sales) OVER (PARTITION BY month_name), 2) AS Avg_sales,
    CASE
        WHEN ROUND(Sales, 2) > ROUND(AVG(Sales) OVER (PARTITION BY month_name), 2) THEN 'Above Average'
        ELSE 'Below Average'
    END AS Result
FROM month_track
ORDER BY month_num,dates;

-- Product Categories Analysis
SELECT 
    product_category,
    concat('$ ',round(SUM(transaction_qty * unit_price),2)) AS sales
FROM cafe_shop_sales
GROUP BY product_category
ORDER BY round(SUM(transaction_qty * unit_price),2) DESC;

-- Top Product Category in details
SELECT 
    product_type,
    round(SUM(transaction_qty * unit_price),2) AS sales
FROM cafe_shop_sales
WHERE product_category = (
    SELECT TOP 1 product_category
    FROM cafe_shop_sales
    GROUP BY product_category
    ORDER BY SUM(transaction_qty * unit_price) DESC
)
GROUP BY product_type
ORDER BY sales DESC;

-- Top 10 Products
SELECT 
    product_type,
    product_category,
    round(SUM(transaction_qty * unit_price),2) AS sales
FROM cafe_shop_sales
GROUP BY product_type, product_category
ORDER BY sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- For "LIMIT 10" equivalent

-- Week days SALES in details
SELECT 
    DATEPART(WEEKDAY, transaction_date) AS day_number,
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday'
        ELSE 'Saturday'
    END AS Day_of_week,
    round(SUM(transaction_qty * unit_price),2) AS sales
FROM cafe_shop_sales
GROUP BY DATEPART(WEEKDAY, transaction_date)
ORDER BY sales DESC;

--Sales by Hours of the transaction
SELECT 
    DATEPART(HOUR, transaction_time) AS Hours,
    ROUND(SUM(transaction_qty * unit_price), 2) AS sales
FROM cafe_shop_sales
GROUP BY DATEPART(HOUR, transaction_time)
ORDER BY Hours;

-- Hourly Sales by Day of Week
SELECT 
    DATEPART(HOUR, transaction_time) AS Hours,
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday'
        ELSE 'Saturday'
    END AS Day_of_week,
    ROUND(SUM(transaction_qty * unit_price), 2) AS sales
FROM cafe_shop_sales
GROUP BY DATEPART(HOUR, transaction_time), DATEPART(WEEKDAY, transaction_date)
ORDER BY Hours, DATEPART(WEEKDAY, transaction_date);

--Hourly Sales with Orders and Sold Items for specific Month
SELECT 
    DATEPART(HOUR, transaction_time) AS Hours,
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday'
        WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday'
        ELSE 'Saturday'
    END AS Day_of_week,
    ROUND(SUM(transaction_qty * unit_price), 2) AS sales,
    COUNT(*) AS Orders,
    SUM(transaction_qty) AS Sold_items
FROM cafe_shop_sales
WHERE MONTH(transaction_date) = 2 -- Select February
GROUP BY DATEPART(HOUR, transaction_time), DATEPART(WEEKDAY, transaction_date)
ORDER BY Hours, DATEPART(WEEKDAY, transaction_date);

--Transaction Day analysis
SELECT 
    DATEPART(WEEKDAY, transaction_date) AS day_number,
    transaction_date,
    DATENAME(WEEKDAY, transaction_date) AS day_name
FROM cafe_shop_sales
GROUP BY transaction_date
order by transaction_date;
