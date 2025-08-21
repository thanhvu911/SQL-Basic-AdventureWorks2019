/* 
Question 1
Request: Retrieve the most common error encountered during production for each product
Source: Tables Production.WorkOrder and Production.ScrapReason
*/
;WITH t1 AS (
	SELECT ProductID, ScrapReasonID ,SUM(ScrappedQty) AS ScrappedQty, SUM(OrderQty) AS OrderQty
	FROM Production.WorkOrder 
	WHERE ScrapReasonID IS NOT NULL
	GROUP BY ProductID, ScrapReasonID
), t2 AS (
SELECT ProductID,MAX(ScrappedQty) AS MaxScrappedQty, SUM(ScrappedQty) AS TotalScrappedQty, SUM(OrderQty) AS TotalOrderQty
FROM t1
GROUP BY ProductID
)
SELECT t1.ProductID, t1.ScrapReasonID, sr.Name AS ScrapReasonName, t2.MaxScrappedQty, t2.TotalScrappedQty, t2.TotalOrderQty, 
t2.MaxScrappedQty * 1.0 / t2.TotalOrderQty AS ScapRatio
FROM t2 JOIN t1 ON t2.ProductID = t1.ProductID AND t2.MaxScrappedQty = t1.ScrappedQty
JOIN Production.ScrapReason sr ON t1.ScrapReasonID = sr.ScrapReasonID
ORDER BY t1.ProductID, t1.ScrapReasonID;

/* 
Question 2
Request: Calculate the average production time (in hours) for each product
Source: Tables Production.Product, Production.ProductSubcategory, Production.ProductCategory, Production.WorkOrder
*/

SELECT WorkOrderID, ProductID, StockedQty, StartDate, EndDate, DATEDIFF(SECOND, StartDate, EndDate) AS Duration
FROM Production.WorkOrder;

SELECT ProductID, SUM(StockedQty) AS Quantity, SUM(DATEDIFF(SECOND, StartDate, EndDate)) AS Duration
FROM Production.WorkOrder
GROUP BY ProductID;

SELECT ProductID, Duration / Quantity / (60 * 60) AS AvgProductionTime
FROM (SELECT ProductID, SUM(StockedQty) AS Quantity, SUM(DATEDIFF(SECOND, StartDate, EndDate)) AS Duration
      FROM Production.WorkOrder
      GROUP BY ProductID
	  ) wo
ORDER BY ProductID;

WITH p AS (
    SELECT p.ProductID, p.Name AS ProductName, c.Name AS ProductCategoryName, 
           sc.Name AS ProductSubcategoryName,
           CASE p.ProductLine 
                WHEN 'R' THEN 'Road' 
                WHEN 'M' THEN 'Mountain' 
                WHEN 'T' THEN 'Touring' 
                WHEN 'S' THEN 'Standard' 
           END AS ProductLine
    FROM Production.Product p
    JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID
),
wo AS (
    SELECT ProductID, SUM(StockedQty) AS Qty, 
           SUM(DATEDIFF(SECOND, StartDate, EndDate)) AS Dur
    FROM Production.WorkOrder
    GROUP BY ProductID
)
SELECT p.ProductCategoryName, p.ProductSubcategoryName, p.ProductID, p.ProductName, p.ProductLine,
       ROUND(wo.Dur * 1.0 / wo.Qty / 3600, 2) AS AvgProductionTime
FROM p JOIN wo ON p.ProductID = wo.ProductID
ORDER BY p.ProductCategoryName, p.ProductSubcategoryName, p.ProductName;

/* 
Question 3
Request: Write a query to create a view that returns monthly sales data for each product (vMonthlySalesByProducts)
Source: Tables Sales.SalesOrderHeader, Sales.SalesOrderDetail, Production.Product, Production.ProductSubcategory, Production.ProductCategory
*/
CREATE OR ALTER VIEW dbo.vMonthlySalesByProducts AS
SELECT YEAR(h.OrderDate) AS [Year],
       EOMONTH(h.OrderDate) AS EndOfMonth,
       c.ProductCategoryID, c.Name AS Category,
       sc.ProductSubcategoryID, sc.Name AS Subcategory,
       p.ProductID, p.Name AS Product,
       SUM(d.OrderQty) AS Qty,
       SUM(d.LineTotal) AS Amount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID
GROUP BY YEAR(h.OrderDate), EOMONTH(h.OrderDate),
         c.ProductCategoryID, c.Name, sc.ProductSubcategoryID, sc.Name,
         p.ProductID, p.Name;
GO

SELECT *
FROM dbo.vMonthlySalesByProducts
ORDER BY EndOfMonth, ProductCategoryID, ProductSubcategoryID, ProductID;


/* 
Question 4
Request: Retrieve the list of products missing a cost record valid until the present (EndDate = NULL)
Source: Tables Production.ProductCostHistory and Production.Product
*/
WITH p_ AS (
    SELECT DISTINCT ProductID
    FROM Production.ProductCostHistory   -- 293 sản phẩm
    EXCEPT
    SELECT DISTINCT ProductID
    FROM Production.ProductCostHistory
    WHERE EndDate IS NULL                -- 195 sản phẩm
)
SELECT p.ProductID, p.Name AS ProductName, p.ProductLine
FROM p_
JOIN Production.Product p 
     ON p_.ProductID = p.ProductID;

/* 
Question 5
Request: For each missing product, add a new row with EndDate = NULL into the product cost history table based on the last row of that product
Source: Table Production.ProductCostHistory
*/
WITH p_thieu AS (
    SELECT DISTINCT ProductID
    FROM Production.ProductCostHistory      -- 293 sp
    EXCEPT
    SELECT DISTINCT ProductID
    FROM Production.ProductCostHistory
    WHERE EndDate IS NULL                   -- 195 sp
),
dong_cuoi AS (
    SELECT pch.*
    FROM Production.ProductCostHistory pch
    JOIN (
        SELECT ProductID, MAX(EndDate) AS MaxEndDate
        FROM Production.ProductCostHistory
        WHERE EndDate IS NOT NULL
        GROUP BY ProductID
    ) dc ON pch.ProductID = dc.ProductID AND pch.EndDate = dc.MaxEndDate
),
pch AS (
    SELECT dc.ProductID, DATEADD(DAY, 1, dc.EndDate) AS StartDate, NULL AS EndDate, dc.StandardCost
    FROM p_thieu p
    JOIN dong_cuoi dc ON p.ProductID = dc.ProductID
    UNION ALL
    SELECT ProductID, StartDate, EndDate, StandardCost
    FROM Production.ProductCostHistory
)
SELECT *
FROM pch
ORDER BY ProductID, StartDate;


/* 
Question 6
Request: Using the virtual table created in Question 4, calculate the daily sales profit in the year 2023
Source: Tables Production.ProductCostHistory, Sales.SalesOrderHeader, Sales.SalesOrderDetail
*/
GO
CREATE OR ALTER VIEW dbo.vProductCostHistory AS
WITH p_thieu AS (
    SELECT DISTINCT ProductID
    FROM Production.ProductCostHistory      -- 293 sp
    EXCEPT
    SELECT DISTINCT ProductID
    FROM Production.ProductCostHistory
    WHERE EndDate IS NULL                   -- 195 sp
),
dong_cuoi AS (
    SELECT pch.*
    FROM Production.ProductCostHistory pch
    JOIN (
        SELECT ProductID, MAX(EndDate) AS MaxEndDate
        FROM Production.ProductCostHistory
        WHERE EndDate IS NOT NULL
        GROUP BY ProductID
    ) dc ON pch.ProductID = dc.ProductID AND pch.EndDate = dc.MaxEndDate
),
pch AS (
    SELECT dc.ProductID, DATEADD(DAY, 1, dc.EndDate) AS StartDate, NULL AS EndDate, dc.StandardCost
    FROM p_thieu p
    JOIN dong_cuoi dc ON p.ProductID = dc.ProductID
    UNION ALL
    SELECT ProductID, StartDate, EndDate, StandardCost
    FROM Production.ProductCostHistory
)
SELECT *
FROM pch
GO



SELECT OrderDate,
       ROUND(SUM(LineTotal),2) AS SalesAmount,
       ROUND(SUM(COGS),2) AS COGS,
       ROUND(SUM(Revenue),2) AS Revenue
FROM (
    SELECT h.OrderDate, d.LineTotal,
           pch.StandardCost*d.OrderQty AS COGS,
           d.LineTotal - pch.StandardCost*d.OrderQty AS Revenue
    FROM Sales.SalesOrderHeader h
    JOIN Sales.SalesOrderDetail d ON h.SalesOrderID=d.SalesOrderID
    JOIN dbo.vProductCostHistory pch 
         ON d.ProductID=pch.ProductID
        AND h.OrderDate BETWEEN pch.StartDate AND ISNULL(pch.EndDate,h.OrderDate)
    WHERE YEAR(h.OrderDate)=2013
) s
GROUP BY OrderDate
ORDER BY OrderDate;
