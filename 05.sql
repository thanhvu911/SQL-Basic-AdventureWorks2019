USE AdventureWorks2019
GO

/* -----------------------------------------------------------------------------------------------------------------
Step 1: Practice querying data based on requirements
*/ 

SELECT TOP(100) * FROM Production.Product
SELECT TOP(100) * FROM Production.[Location]
SELECT TOP(100) * FROM Production.ProductInventory 
SELECT TOP(100) * FROM Sales.vStoreWithContacts

/* 1.1
Requirement: Get the list of products that satisfy the following conditions:
- Product number starts with "FR" and ends with 2 digits (0–9)
- Product color is White, Red, or Black
Data source: Table Production.Product
*/
SELECT ProductID, Name, ProductNumber, Color, Size
FROM Production.Product
WHERE ProductNumber LIKE 'FR%[0-9][0-9]' AND Color IN ('Black', 'Red', 'White')
ORDER BY ProductID

/* 1.2
Requirement: Get the list of products for sale whose inventory quantity is less than or equal to the minimum reorder level.
Data source: Tables Production.Product and Production.ProductInventory
In table Product:
+ Column FinishedGoodsFlag indicates whether it is a product for sale
+ Column ReorderPoint specifies the minimum required inventory level for a product
*/

;WITH p AS (
SELECT c.ProductCategoryID, c.Name as ProductCategoryName, sc.ProductSubcategoryID, sc.Name as ProductSubcategoryName,
    p.ProductID, p.Name as ProductName, ProductNumber,
    CASE ProductLine 
        WHEN 'R' THEN 'Road'
        WHEN 'M' THEN 'Mountain'
        WHEN 'T' THEN 'Touring'
        WHEN 'S' THEN 'Standard'
    END AS ProductLine,
    MakeFlag, FinishedGoodsFlag, ReorderPoint
    FROM Production.Product p
    LEFT JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
), i AS (
SELECT i.ProductID, SUM(Quantity) AS Quantity
    FROM Production.ProductInventory i 
    JOIN p ON i.ProductID = p.ProductID
    WHERE FinishedGoodsFlag = 1
    GROUP BY i.ProductID
)
SELECT p.ProductCategoryName, p.ProductSubcategoryName, p.ProductID, p.ProductName, ReorderPoint, i.Quantity
FROM i 
JOIN p ON i.ProductID = p.ProductID
WHERE Quantity <= ReorderPoint
ORDER BY ProductCategoryID, ProductSubcategoryID, ProductID

/* 1.3
Requirement: Calculate the sales revenue of stores in Europe (Group = Europe) in 2013. 
Filter only stores with revenue above 100,000 and include their contact information.
Data source: Tables Sales.SalesOrderHeader, Sales.SalesOrderDetail, Sales.Customer, Sales.SalesTerritory, Sales.vStoreWithContacts
*/

;WITH sales AS (
    SELECT t.TerritoryID, StoreID, SUM(LineTotal) AS SalesAmount
    FROM Sales.SalesOrderHeader h
    JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID 
    JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
    JOIN Sales.SalesTerritory t ON c.TerritoryID = t.TerritoryID
    WHERE StoreID IS NOT NULL AND [Group] = 'Europe' AND YEAR(OrderDate) = 2013
    GROUP BY t.TerritoryID, StoreID
    HAVING SUM(LineTotal) > 100000
) 
SELECT t.TerritoryID, t.Name AS TerritoryName, 
sales.StoreID, s.Name AS StoreName, s.ContactType, 
CONCAT(s.Title, ' ', s.FirstName, ' ', s.MiddleName, ' ', s.LastName) AS ContactName, 
s.PhoneNumber, sales.SalesAmount
FROM sales 
JOIN Sales.SalesTerritory t ON sales.TerritoryID = t.TerritoryID
JOIN Sales.vStoreWithContacts s ON sales.StoreID = s.BusinessEntityID
ORDER BY t.TerritoryID, StoreID

/* 1.4
Requirement: For each year, classify products in the 'Bikes' category based on the number of units sold.  
If the quantity sold is greater than or equal to the category’s average quantity, label it 'High'; otherwise label it 'Low'.
*/
;WITH p AS (
SELECT c.ProductCategoryID, c.Name as ProductCategoryName, sc.ProductSubcategoryID, sc.Name as ProductSubcategoryName,
    p.ProductID, p.Name as ProductName, ProductNumber,
    CASE ProductLine 
        WHEN 'R' THEN 'Road'
        WHEN 'M' THEN 'Mountain'
        WHEN 'T' THEN 'Touring'
        WHEN 'S' THEN 'Standard'
    END AS ProductLine,
    MakeFlag, FinishedGoodsFlag, ReorderPoint
    FROM Production.Product p
    LEFT JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
), yp AS (
SELECT YEAR(OrderDate) AS [Year], p.ProductID, SUM(OrderQty) AS Quantity
    FROM Sales.SalesOrderDetail d 
    JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
    JOIN p ON d.ProductID = p.ProductID
    WHERE p.ProductCategoryName = 'Bikes'
    GROUP BY YEAR(OrderDate), p.ProductID
), y AS (
SELECT YEAR(OrderDate) AS [Year], COUNT(DISTINCT ProductID) AS NbProducs, SUM(OrderQty) AS Quantity, 
    SUM(OrderQty) * 1.0 /  COUNT(DISTINCT ProductID) AS AvgQuantity
    FROM Sales.SalesOrderDetail d 
    JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
    GROUP BY YEAR(OrderDate)
)

SELECT yp.[Year], yp.ProductID, p.ProductNumber, p.ProductName, p.ProductLine,
yp.Quantity, CASE WHEN yp.Quantity >= y.AvgQuantity THEN N'High' ELSE N'Low' END AS Class 
FROM yp 
JOIN y ON yp.[Year] = y.[Year]
JOIN p ON yp.ProductID = p.ProductID
ORDER BY yp.[Year], yp.ProductID

/* 1.5
Requirement: Report the number of products sold each year for the 'Bikes' category, grouped by ProductSubcategory, Color, and Size.
*/
;WITH p AS (
SELECT c.ProductCategoryID, c.Name as ProductCategoryName, sc.ProductSubcategoryID, sc.Name as ProductSubcategoryName,
    p.ProductID, p.Name as ProductName, ProductNumber,
    CASE ProductLine 
        WHEN 'R' THEN 'Road'
        WHEN 'M' THEN 'Mountain'
        WHEN 'T' THEN 'Touring'
        WHEN 'S' THEN 'Standard'
    END AS ProductLine,
    MakeFlag, FinishedGoodsFlag, Color, [Size]
    FROM Production.Product p
    LEFT JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
)

SELECT YEAR(OrderDate) AS [Year], p.ProductSubcategoryName, p.Color, p.Size, SUM(OrderQty) AS Quantity
FROM Sales.SalesOrderDetail d 
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN p ON d.ProductID = p.ProductID
WHERE p.ProductCategoryName ='Bikes'
GROUP BY YEAR(OrderDate), p.ProductSubcategoryName, p.Color, p.Size
ORDER BY 1, 2, 3, 4

/* -- Topic: Time Series Sales Analysis -- */

/* -----------------------------------------------------------------------------------------------------------------
Step 2: Aggregate sales over time
- Get an overview of the company’s overall business situation
- Track increases/decreases at different time periods
*/
-- 2.1. Sales by year
SELECT FORMAT(OrderDate, 'yyyy') as Year, ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
GROUP BY FORMAT(OrderDate, 'yyyy')
ORDER BY Year

-- 2.2. Sales by month
SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate, 
ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
GROUP BY FORMAT(OrderDate, 'yyyy-MM'), EOMONTH(OrderDate)
ORDER BY YearMonth, EndDate

/* -----------------------------------------------------------------------------------------------------------------
Step 3: Analyze sales trends of a specific category over time.
- Look deeper into one product category
- Track increases/decreases at different times
*/
-- 3.1. Sales of 'Bikes' category by year
SELECT FORMAT(OrderDate, 'yyyy') as Year, c.ProductCategoryID, c.Name as ProductCategoryName, 
ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
WHERE c.Name = 'Bikes'
GROUP BY FORMAT(OrderDate, 'yyyy'), c.ProductCategoryID, c.Name
ORDER BY Year, c.ProductCategoryID

-- 3.2. Sales of 'Bikes' category by month
SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate, c.ProductCategoryID, c.Name as ProductCategoryName, 
ROUND(SUM(LineTotal), 0) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
WHERE c.Name = 'Bikes'
GROUP BY FORMAT(OrderDate, 'yyyy-MM'), EOMONTH(OrderDate), c.ProductCategoryID, c.Name
ORDER BY YearMonth, c.ProductCategoryID

/* -----------------------------------------------------------------------------------------------------------------
Step 4: Analyze sales trends across multiple categories.
- Compare across categories. Each category may have its own trend.
- Categories differ in size.
- PA1: Compare 'Bikes' with 'Components' (the second largest category)
- PA2: Compare 3 non-Bikes categories with each other ('Components', 'Clothing', 'Accessories')
- PA3: Compare 'Bikes' vs. all other categories combined ('Others')
*/ 
-- Sales by category by year
SELECT FORMAT(OrderDate, 'yyyy') as Year, c.ProductCategoryID, c.Name as ProductCategoryName,
CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
GROUP BY FORMAT(OrderDate, 'yyyy'), c.ProductCategoryID, c.Name
ORDER BY Year, c.ProductCategoryID, c.Name

-- 4.1. Sales of 'Bikes' vs. other categories by year
SELECT [Year], ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
FROM
(SELECT FORMAT(OrderDate, 'yyyy') as Year,
    CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
    CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
    LineTotal
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p on d.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
) s
GROUP BY Year, ProductCategoryID, ProductCategoryName
ORDER BY Year, ProductCategoryID

-- 4.2. Sales of categories by month in 2012 and 2013
SELECT YearMonth, EndDate, ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
FROM
(SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate,
    CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
    CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
    LineTotal
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p on d.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
    WHERE YEAR(OrderDate) IN (2012, 2013)
) s
GROUP BY YearMonth, EndDate, ProductCategoryID, ProductCategoryName
ORDER BY YearMonth, EndDate, ProductCategoryID

/* -----------------------------------------------------------------------------------------------------------------
Step 5: Analyze sales differences, ratios between 'Bikes' and other categories, and % of total sales from 'Bikes'
*/ 
-- 5.1. By year
;WITH s AS (
SELECT [Year], ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
    FROM
    (SELECT FORMAT(OrderDate, 'yyyy') as Year,
        CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
        CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
        LineTotal
        FROM Sales.SalesOrderDetail d
        JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
        JOIN Production.Product p on d.ProductID = p.ProductID
        JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
        JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
    ) s
    GROUP BY Year, ProductCategoryID, ProductCategoryName
), yearly AS (
SELECT [Year], 
    SUM(CASE WHEN ProductCategoryName='Bikes' THEN SalesAmount ELSE 0 END) AS Bikes,
    SUM(CASE WHEN ProductCategoryName='Others' THEN SalesAmount ELSE 0 END) AS Others,
    SUM(SalesAmount) AS [Total]
    FROM s
    GROUP BY [Year]
) 

SELECT [Year], Bikes - Others AS Difference, ROUND(Bikes / Others, 1) AS Ratio, 
ROUND(Bikes * 100 / Total, 2) AS BikesPercentOfTotal, ROUND(Others * 100 / Total, 2) AS OthersPercentOfTotal
FROM yearly
ORDER BY [YEAR]

-- 5.2. By month
;WITH s AS (
SELECT YearMonth, EndDate, ProductCategoryID, ProductCategoryName, CONVERT(DECIMAL(18,0), SUM(LineTotal)) as SalesAmount
    FROM
    (SELECT FORMAT(OrderDate, 'yyyy-MM') as YearMonth, EOMONTH(OrderDate) AS EndDate,
        CASE WHEN c.Name='Bikes' THEN c.ProductCategoryID ELSE 0 END AS ProductCategoryID, 
        CASE WHEN c.Name='Bikes' THEN c.Name ELSE 'Others' END AS ProductCategoryName, 
        LineTotal
        FROM Sales.SalesOrderDetail d
        JOIN Sales.SalesOrderHeader h on h.SalesOrderID = d.SalesOrderID
        JOIN Production.Product p on d.ProductID = p.ProductID
        JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
        JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
        WHERE YEAR(OrderDate) IN (2012, 2013)
    ) s
    GROUP BY YearMonth, EndDate, ProductCategoryID, ProductCategoryName
), monthly AS (
SELECT YearMonth, EndDate, 
    SUM(CASE WHEN ProductCategoryName='Bikes' THEN SalesAmount ELSE 0 END) AS Bikes,
    SUM(CASE WHEN ProductCategoryName='Others' THEN SalesAmount ELSE 0 END) AS Others,
    SUM(SalesAmount) AS [Total]
    FROM s
    GROUP BY YearMonth, EndDate
) 

SELECT YearMonth, EndDate, Bikes - Others AS Difference, ROUND(Bikes / Others, 1) AS Ratio, 
ROUND(Bikes * 100 / Total, 2) AS BikesPercentOfTotal, ROUND(Others * 100 / Total, 2) AS OthersPercentOfTotal
FROM monthly
ORDER BY YearMonth, EndDate
