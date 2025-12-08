CREATE OR REPLACE TABLE Sales.Dataset.Table1_clean AS
SELECT
Date,
Sales,
Cost_of_Sales,
Quantity_Sold,

-----Daily price per unit
Sales / NULLIF(Quantity_Sold, 0) AS Price_per_Unit,

-----Gross profit (Rand)
Sales - Cost_of_Sales AS Gross_Profit,

-----% Gross Profit
(Sales - Cost_of_Sales) / NULLIF(Sales, 0) AS Gross_Profit_Percent,

-----Gross Profit per Unit
(Sales - Cost_of_Sales) / NULLIF(Quantity_Sold, 0) AS Gross_Profit_per_Unit

FROM Sales.Dataset.Table1
ORDER BY Date;


-----Average Unit Sales Price
SELECT 
AVG(Sales / NULLIF(Quantity_Sold, 0)) AS Avg_Unit_Sales_Price
FROM Sales.Dataset.Table1;

-----Daily % Gross Profit
SELECT
Date,
(Sales - Cost_of_Sales) / NULLIF(Sales, 0) AS Gross_Profit_Percent
FROM Sales.Dataset.Table1_clean;

-----Daily Gross Profit per Unit

SELECT
Date,
Gross_Profit_per_Unit
FROM Sales.Dataset.Table1_clean;

-----Identify Promotion Days (price far below normal)
CREATE OR REPLACE TABLE Sales.Dataset.Price_Stats AS
SELECT
AVG(Price_per_Unit) AS Avg_Price,
STDDEV(Price_per_Unit) AS Std_Price
FROM Sales.Dataset.Table1_clean;
-----------------------------------------------------------------
CREATE OR REPLACE TABLE Sales.Dataset.Table1_promos AS
SELECT
s.*,
CASE WHEN Price_per_Unit < (p.Avg_Price - p.Std_Price)
THEN 1 ELSE 0 END AS Promotion_Flag
FROM Sales.Dataset.Table1_clean s
CROSS JOIN Sales.Dataset.Price_Stats p;
------------------------------------------------------------------
CREATE OR REPLACE TABLE Sales.Dataset.Promotion_Periods AS
WITH flagged AS (
SELECT
Date,
Promotion_Flag,
ROW_NUMBER() OVER (ORDER BY Date) AS rn,
ROW_NUMBER() OVER (ORDER BY Date) 
- SUM(Promotion_Flag) OVER (ORDER BY Date ROWS UNBOUNDED PRECEDING) AS grp
FROM Sales.Dataset.Table1_promos
)
SELECT
grp,
MIN(Date) AS Promo_Start,
MAX(Date) AS Promo_End,
COUNT(*) AS Days
FROM flagged
WHERE Promotion_Flag = 1
GROUP BY grp
ORDER BY Promo_Start;
------------------------------------------------------------------
SELECT *
FROM sales.dataset.table1_clean;
