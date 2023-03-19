
--checking imported data 
SELECT * FROM rfm..sales;

-- EXPLORATORY ANALYSIS
-- Explore the data to check for distinct values 
SELECT DISTINCT status FROM rfm..sales;
SELECT DISTINCT year_id FROM rfm..sales;
SELECT DISTINCT productline FROM rfm..sales;
SELECT DISTINCT country FROM rfm..sales;
SELECT DISTINCT dealsize FROM rfm..sales;
SELECT DISTINCT territory FROM rfm..sales;

-- Which productline made most sales ?
SELECT productline, ROUND(SUM(sales),2) AS revenue 
FROM rfm..sales
GROUP BY productline 
ORDER BY revenue DESC;

-- Which year most sales was made ?
SELECT year_id, ROUND(SUM(sales),2) AS revenue 
FROM rfm..sales 
GROUP BY year_id 
ORDER BY revenue DESC;

/*The result shows 2005 as the lowest earning year 
2004	4724162.59
2003	3516979.55
2005	1791486.71
lets dig deeper in the year 2005 */

SELECT DISTINCT month_id FROM rfm..sales WHERE year_id = 2005;
-- we found out tht only few months sales is recorded for year 2005 


-- which dealsize generated most revenue ?
SELECT dealsize, ROUND(SUM(sales),0) AS revenue 
FROM rfm..sales 
GROUP BY dealsize;

-- FIND BEST MONTH FOR SALES in each specific year ?
SELECT month_id, ROUND(SUM(sales),0) AS revenue 
FROM rfm..sales 
WHERE year_id = 2003 
GROUP BY month_id
ORDER BY 2 DESC;

SELECT month_id, ROUND(SUM(sales),0) AS revenue 
FROM rfm..sales 
WHERE year_id = 2004 
GROUP BY month_id
ORDER BY 2 DESC;
-- NOVEMBER HAD THE GREATEST REVENUE COLLECTION 


-- What products is sold in november 
SELECT month_id, productline, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS order_count
FROM rfm..sales
WHERE year_id = 2003 AND month_id = 11 
GROUP BY month_id,PRODUCTLINE
ORDER BY 3 DESC; -- classic cars were most sold in novermber 2003 

SELECT month_id, productline, ROUND(SUM(sales),0) AS revenue, COUNT(ordernumber) AS order_count
FROM rfm..sales
WHERE year_id = 2004 AND month_id = 11 
GROUP BY month_id,PRODUCTLINE
ORDER BY 3 DESC; -- classic cars were most sold in novermber 2004

-- ===========LETS DO RFM ANALYSIS NOW : ====================================================================================

/* It used past purchase behavior to segment customers.
RFM REPORT : segments customers uing three key metrices : 
RECENCY : How long ago last purchase was ?
FREQUENCY : How often they purchase ?
MONETARY VALUE : How much they spent ?
*/
--===========================================================================================================================

-- 1 > RECENCY : 
--  put the sales data in 4 equal buckets according to recency 
-- using a temp table
DROP table if exists #rfm1
;with rfm1 AS 
(SELECT 
	customername,
	ROUND(SUM(sales),0) AS monetary_value,
	ROUND(AVG(sales),0) AS avg_monetary_value,
	COUNT(ordernumber) AS frequency,
	MAX(orderdate) AS last_order_date,
	(SELECT MAX(orderdate) FROM rfm..sales) AS max_order_date,
	DATEDIFF(DD,MAX(orderdate),(SELECT MAX(orderdate) FROM rfm..sales)) AS recency 
FROM rfm..sales
GROUP BY customername
),
rfm_cal as
(
	SELECT r.*,
		NTILE(4) OVER (order by recency DESC) AS rfm_recency,
		NTILE(4) OVER (order BY frequency) AS rfm_frequency,
		NTILE(4) OVER (order BY monetary_value) AS rfm_monetary
	FROM rfm1 r
)
SELECT c.* , rfm_recency + rfm_monetary+rfm_frequency AS rfm_cell,
CAST(rfm_recency AS varchar) + CAST(rfm_monetary AS varchar) + CAST(rfm_frequency AS varchar) AS rfm_cell_string
into #rfm1
FROM rfm_cal c;



SELECT customername,rfm_recency,rfm_frequency,rfm_monetary,
 CASE 
	WHEN rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) THEN 'Lost Customers'
	WHEN rfm_cell_string in (133,134,143,244,334,343,344) THEN 'Valuable customers that might leave'
	WHEN rfm_cell_string in (311,411,331) THEN 'New customers'
	WHEN rfm_cell_string in (222,223,233,322) THEN 'Potential Customers'
	WHEN rfm_cell_string in (323,333,321,422,332,432) THEN 'Active customers'
	WHEN rfm_cell_string in (433,434,443,444) THEN 'Loyal'
END rfm_segment 
FROM #rfm1


-========================================================================================================================

-- What TWO products are most often sold together ?
--select * from rfm..sales where ordernumber = 10411;
