USE AdventureWorks2019
GO

/* -----------------------------------------------------------------------------------------------------------------
Step 1: Practice SQL Subqueries
*/

-- 1.1. Get the list of the youngest employees in the company
SELECT BusinessEntityID as EmployeeID, NationalIDNumber, JobTitle, BirthDate, MaritalStatus, Gender, YEAR(GETDATE()) - YEAR(BirthDate) AS Age
FROM HumanResources.Employee 
WHERE YEAR(BirthDate) = (SELECT MAX(YEAR(BirthDate)) FROM HumanResources.Employee)
ORDER BY BusinessEntityID

-- 1.2. Get the list of the oldest employees in the company 
SELECT BusinessEntityID as EmployeeID, NationalIDNumber, JobTitle, BirthDate, MaritalStatus, Gender, YEAR(GETDATE()) - YEAR(BirthDate) AS Age
FROM HumanResources.Employee 
WHERE YEAR(BirthDate) = (SELECT MIN(YEAR(BirthDate)) FROM HumanResources.Employee)
ORDER BY BusinessEntityID

-- 1.3. Get the list of products that sold more than 1000 units in 2012
-- Step 1: JOIN Sales.SalesOrderDetail and Sales.SalesOrderHeader to get the product IDs with sales over 1000 units in 2012
SELECT  ProductID
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
WHERE YEAR(OrderDate) = 2012
GROUP BY ProductID
HAVING SUM(OrderQty) > 1000

-- Step 2: Retrieve product information from Production.Product, Production.ProductSubcategory, and Production.ProductCategory
-- Method 1: Use Subqueries in the WHERE clause
SELECT c.ProductCategoryID, c.Name as ProductCategoryName, sc.ProductSubcategoryID, sc.Name as ProductSubcategoryName,
ProductID, p.Name as ProductName, ProductNumber, Color, 
CASE ProductLine 
    WHEN 'R' THEN 'Road'
    WHEN 'M' THEN 'Mountain'
    WHEN 'T' THEN 'Touring'
    WHEN 'S' THEN 'Standard'
END AS ProductLine
FROM Production.Product p
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
WHERE ProductID in (
    SELECT  ProductID
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
    WHERE YEAR(OrderDate) = 2012
    GROUP BY ProductID
    HAVING SUM(OrderQty) > 1000
)
ORDER BY c.ProductCategoryID, sc.ProductSubcategoryID, p.ProductID

-- Method 2: Create a derived table from Step 1 query, then JOIN with other tables to get more details
SELECT c.ProductCategoryID, c.Name as ProductCategoryName, sc.ProductSubcategoryID, sc.Name as ProductSubcategoryName,
p.ProductID, p.Name as ProductName, ProductNumber, Color, 
CASE ProductLine 
    WHEN 'R' THEN 'Road'
    WHEN 'M' THEN 'Mountain'
    WHEN 'T' THEN 'Touring'
    WHEN 'S' THEN 'Standard'
END AS ProductLine, Quantity
FROM Production.Product p
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
JOIN (
    SELECT  ProductID, SUM(OrderQty) AS Quantity
    FROM Sales.SalesOrderDetail d
    JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
    WHERE YEAR(OrderDate) = 2012
    GROUP BY ProductID
    HAVING SUM(OrderQty) > 1000
) r on r.ProductID = p.ProductID
ORDER BY c.ProductCategoryID, sc.ProductSubcategoryID, p.ProductID

;WITH s AS (
    SELECT CustomerID, COUNT(SalesOrderID) as NbOrders
    FROM Sales.SalesOrderHeader
    WHERE  YEAR(OrderDate) = 2012
    GROUP BY CustomerID
)
SELECT COUNT(CustomerID) as NbCustomers, SUM(NbOrders) as NbOrders, 
MIN(NbOrders) as MinOrdersPerCustomer, MAX(NbOrders) as MaxOrdersPerCustomer, AVG(NbOrders*1.0) as AvgOrdersPerCustomer
FROM s

-- 2.2. Compare the number of customers and orders in 2012 with 2011
-- Step 1: Summarize sales data by year
SELECT YEAR(OrderDate) as [Year], COUNT(DISTINCT CustomerID) as NbCustomers, COUNT(SalesOrderID) as NbOrders
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)

-- Step 2: Build CTE s for reuse
;WITH s AS (
SELECT YEAR(OrderDate) as [Year], COUNT(DISTINCT CustomerID) as NbCustomers, COUNT(SalesOrderID) as NbOrders
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
)
SELECT * FROM s

-- Step 3: Calculate the growth rate of 2012 compared to 2011
;WITH s AS (
SELECT YEAR(OrderDate) as [Year], COUNT(DISTINCT CustomerID) as NbCustomers, COUNT(SalesOrderID) as NbOrders
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
)
SELECT s1.[Year], 
s1.NbCustomers as NbCustomers2012, s2.NbCustomers as NbCustomers2011,
ROUND((s1.NbCustomers - s2.NbCustomers) * 100.00 / s2.NbCustomers, 2) AS [CustomerGrowthRate],
s1.NbOrders as NbOrders2012, s2.NbOrders as NbOrders2011,
ROUND((s1.NbOrders - s2.NbOrders) * 100.00 / s2.NbOrders, 2) AS [OrderGrowthRate]
FROM s s1, s s2
WHERE s1.[Year] = 2012 AND s2.[Year] = 2011

-- 2.3. Build Fibonacci sequence
;WITH f(RowIndex) AS (
    SELECT 1 AS RowIndex
    UNION ALL
    SELECT RowIndex + 1
    FROM f 
    WHERE f.RowIndex < 10
)
SELECT * FROM f

;WITH f(RowIndex, CurrentValue, NextValue) AS (
    SELECT 1 AS RowIndex, 1 AS CurrentValue, 1 AS NextValue
    UNION ALL
    SELECT f.RowIndex + 1 AS RowIndex, NextValue AS CurrentValue, CurrentValue + NextValue AS NextValue
    FROM f 
    WHERE f.RowIndex <= 10
)
SELECT * FROM f

-- 2.4. Get the organizational hierarchy including employee and their direct manager information
-- Step 1: Build a temporary table o storing employees and their Path in the org tree
;WITH o AS (
    SELECT e.BusinessEntityID as EmployeeID, 
    OrganizationNode.ToString() as [Path], OrganizationLevel as [Level],
    CONCAT(p.FirstName,' ', p.MiddleName,' ', p.LastName) as EmployeeName,
    e.JobTitle 
    FROM HumanResources.Employee e 
    JOIN Person.Person p on e.BusinessEntityID = p.BusinessEntityID
)
SELECT * FROM o

-- Step 2:
;WITH o AS (
    SELECT e.BusinessEntityID AS EmployeeID, OrganizationNode.ToString() AS [Path], OrganizationLevel AS [Level],
    CONCAT(p.FirstName, ' ', p.MiddleName, ' ', p.LastName) AS EmployeeName,
    e.JobTitle
    FROM HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
), h AS (
    SELECT EmployeeID , [Path], [Level], NULL AS ManagerID 
    FROM o WHERE [Level] IS NULL
    UNION ALL 
    SELECT EmployeeID , [Path], [Level], 1 AS ManagerID 
    FROM o WHERE [Level] = 1
    UNION ALL
    SELECT o.EmployeeID , o.[Path], o.[Level], h.EmployeeID AS ManagerID
    FROM o
    JOIN h on LEFT(o.[Path], LEN(h.[Path])) = h.[Path] AND o.[Level] = h.[Level] + 1
)
SELECT * FROM h

-- Step 3: Add more details about employees and managers
;WITH o AS (
    SELECT e.BusinessEntityID AS EmployeeID, OrganizationNode.ToString() AS [Path], OrganizationLevel AS [Level],
    CONCAT(p.FirstName, ' ', p.MiddleName, ' ', p.LastName) AS EmployeeName,
    e.JobTitle
    FROM HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
), h AS (
    SELECT EmployeeID , [Path], [Level], NULL AS ManagerID 
    FROM o WHERE [Level] IS NULL
    UNION ALL 
    SELECT EmployeeID , [Path], [Level], 1 AS ManagerID 
    FROM o WHERE [Level] = 1
    UNION ALL
    SELECT o.EmployeeID , o.[Path], o.[Level], h.EmployeeID AS ManagerID
    FROM o
    JOIN h on LEFT(o.[Path], LEN(h.[Path])) = h.[Path] AND o.[Level] = h.[Level] + 1
)
SELECT h.EmployeeID, oe.EmployeeName, oe.JobTitle, h.[Path], h.[Level], 
h.ManagerID, om.EmployeeName as ManagerName, om.JobTitle as ManagerTitle
FROM h
LEFT JOIN o oe on h.EmployeeID = oe.EmployeeID
LEFT JOIN o om on h.ManagerID = om.EmployeeID
ORDER BY h.[Path]

--SELECT SUBSTRING('/1/2/', 2, LEN('/1/2/') - 2)
 /* -----------------------------------------------------------------------------------------------------------------
Step 3: Practice Views
*/
-- 3.1. Query to get information about reseller stores with Demographics
SELECT BusinessEntityID, Name, BusinessType, YearOpened, NumberEmployees 
FROM Sales.vStoreWithDemographics ORDER BY BusinessEntityID

-- 3.2. Create a view to get product catalog information
-- Step 1: 
GO
CREATE OR ALTER VIEW [dbo].[vProductCatalog]
AS 
SELECT -- product hierarchy including: product ID, product name, subcategory ID, subcategory name, category ID, category name
c.ProductCategoryID, c.Name as ProductCategoryName,
sc.ProductSubcategoryID, sc.Name as ProductSubcategoryName,
p.ProductID, p.Name as ProductName
FROM Production.Product p
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
-- ORDER BY c.ProductCategoryID, sc.ProductSubcategoryID, p.ProductID
GO

-- Step 2: Query the created view
SELECT ProductCategoryID, ProductCategoryName, ProductSubcategoryID, ProductSubcategoryName, ProductID, ProductName
FROM dbo.vProductCatalog
ORDER BY ProductCategoryID, ProductSubcategoryID, ProductID

--------------------------------------------------------------------------------------------
-- Generate numbers from 1 to 10
;WITH f(RowIndex) AS (
    SELECT 1 AS RowIndex
    UNION ALL
    SELECT RowIndex + 1
    FROM f 
    WHERE f.RowIndex < 10
)
SELECT * FROM f
