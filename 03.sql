USE AdventureWorks2019
GO

/* -----------------------------------------------------------------------------------------------------------------
1. Practice SQL (INNER) JOIN
*/
-- 1.1. Get the list of individual customers
-- Step 1: Get the list of individual customer IDs from the Sales.Customer table
SELECT CustomerID, PersonID, TerritoryID
FROM Sales.Customer c
WHERE c.StoreID IS NULL

-- Step 2: Add customer names from the Person.Person table
SELECT CustomerID, PersonID, TerritoryID, CONCAT(p.FirstName,' ',p.MiddleName,' ',p.LastName) as CustomerName
FROM Sales.Customer c
JOIN Person.Person p on c.PersonID = p.BusinessEntityID
WHERE c.StoreID IS NULL
ORDER BY CustomerID

-- 1.2. Get the product hierarchy including: product ID, product name, subcategory ID, subcategory name, category ID, category name
-- Method 1: From Category > Subcategory > Product
SELECT c.ProductCategoryID, c.Name AS ProductCategoryName,
sc.ProductSubcategoryID, sc.Name AS ProductSubcategoryName, 
p.ProductID, p.Name AS ProductName
FROM Production.ProductCategory c 
JOIN Production.ProductSubcategory sc ON c.ProductCategoryID = sc.ProductCategoryID
JOIN Production.Product p ON sc.ProductSubcategoryID = p.ProductSubcategoryID
ORDER BY c.ProductCategoryID, sc.ProductSubcategoryID, p.ProductID

SELECT 
p.ProductID, p.Name AS ProductName,
sc.ProductSubcategoryID, sc.Name AS ProductSubcategoryName,
c.ProductCategoryID, c.Name AS ProductCategoryName
FROM Production.ProductCategory c 
JOIN Production.ProductSubcategory sc ON c.ProductCategoryID = sc.ProductCategoryID
JOIN Production.Product p ON sc.ProductSubcategoryID = p.ProductSubcategoryID
ORDER BY c.ProductCategoryID, sc.ProductSubcategoryID, p.ProductID

-- Method 2: From Product > Subcategory > Category
SELECT p.ProductID, p.Name AS ProductName,
sc.ProductSubcategoryID, sc.Name AS ProductSubcategoryName,
c.ProductCategoryID, c.Name AS ProductCategoryName
FROM Production.Product p 
JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c ON sc.ProductCategoryID = c.ProductCategoryID
ORDER BY c.ProductCategoryID, sc.ProductSubcategoryID, p.ProductID

-- 1.3. Get the revenue of products in the 'Road Bikes' subcategory by month in 2012

SELECT TOP(100) SalesOrderID, OrderDate, TotalDue FROM Sales.SalesOrderHeader
SELECT TOP(100) SalesOrderID, SalesOrderDetailID, ProductID, OrderQty, UnitPrice, LineTotal FROM Sales.SalesOrderDetail

-- Step 1: Select necessary columns OrderDate, ProductID, LineTotal for aggregation
SELECT h.OrderDate, d.ProductID, d.LineTotal 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
WHERE YEAR(h.OrderDate) = 2012

-- Step 2: Join Product and ProductSubcategory to filter products in 'Road Bikes'
SELECT h.OrderDate, d.ProductID, d.LineTotal 
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
WHERE YEAR(h.OrderDate) = 2012 and sc.Name = 'Road Bikes'

-- Step 3: Extract YearMonth from OrderDate
SELECT FORMAT(h.OrderDate, 'yyyy-MM') as YearMonth, d.ProductID, d.LineTotal
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
WHERE YEAR(h.OrderDate) = 2012 and sc.Name = 'Road Bikes'

-- Step 4: Aggregate revenue by month and product
SELECT FORMAT(h.OrderDate, 'yyyy-MM') as YearMonth, d.ProductID, SUM(d.LineTotal) as TotalAmount
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h on d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
WHERE YEAR(h.OrderDate) = 2012 and sc.Name = 'Road Bikes'
GROUP BY FORMAT(h.OrderDate, 'yyyy-MM'),d.ProductID
ORDER BY YearMonth, d.ProductID

-- Method 2: End of Month
SELECT EOMONTH(h.OrderDate) AS EndDateOfMonth, d.ProductID, SUM(d.LineTotal) AS TotalAmount
FROM Sales.SalesOrderDetail d 
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
WHERE YEAR(OrderDate) = 2012 AND sc.Name = 'Road Bikes'
GROUP BY EOMONTH(h.OrderDate), d.ProductID
ORDER BY [EndDateOfMonth], d.ProductID

-- Method 3: Year, Month
SELECT YEAR(h.OrderDate) AS [Year], MONTH(h.OrderDate) AS [Month], d.ProductID, SUM(d.LineTotal) AS TotalAmount
FROM Sales.SalesOrderDetail d 
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
WHERE YEAR(OrderDate) = 2012 AND sc.Name = 'Road Bikes'
GROUP BY YEAR(h.OrderDate), MONTH(h.OrderDate), d.ProductID
ORDER BY [Year], [Month], d.ProductID

-- 1.4. Get the revenue of individual customers for each month of Q3 and Q4 of 2012 (from July 2012 to December 2012)
-- Step 1: Select necessary fields from Sales.SalesOrderHeader
SELECT OrderDate, CustomerID, TotalDue
FROM Sales.SalesOrderHeader

-- Step 2: Join with Sales.Customer and Person.Person, filter for individual customers
SELECT OrderDate, c.PersonID, c.CustomerID, TotalDue
FROM Sales.SalesOrderHeader h 
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
--JOIN Person.Person p on c.PersonID = p.BusinessEntityID
WHERE OrderDate>= '2012-07-01' and OrderDate<= '2012-12-31'
    and c.StoreID IS NULL -- and p.PersonType = 'IN'

-- Step 3: Aggregate revenue by month
SELECT FORMAT(h.OrderDate, 'yyyy-MM') as YearMonth, c.CustomerID, c.PersonID, SUM(TotalDue) as TotalAmount
FROM Sales.SalesOrderHeader h 
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE OrderDate>= '2012-07-01' and OrderDate<= '2012-12-31' 
    and c.StoreID IS NULL
GROUP BY FORMAT(h.OrderDate, 'yyyy-MM'), c.CustomerID, c.PersonID

-- Step 4: Add customer information
-- Method 1:
SELECT FORMAT(h.OrderDate, 'yyyy-MM') as YearMonth, c.CustomerID,
CONCAT(p.FirstName,' ',p.LastName) as CustomerName, p.PersonType as CustomerType,
SUM(TotalDue) as TotalAmount
FROM Sales.SalesOrderHeader h 
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
JOIN Person.Person p on c.PersonID = p.BusinessEntityID
WHERE OrderDate>= '2012-07-01' and OrderDate<= '2012-12-31' 
    and c.StoreID IS NULL
GROUP BY FORMAT(h.OrderDate, 'yyyy-MM'), c.CustomerID, CONCAT(p.FirstName,' ',p.LastName), p.PersonType
ORDER BY 1, 2

-- Method 2:
SELECT YearMonth, CustomerID, CONCAT(p.FirstName,' ',p.LastName) as CustomerName,  p.PersonType as CustomerType, TotalAmount
FROM
(SELECT FORMAT(h.OrderDate, 'yyyy-MM') as YearMonth, c.CustomerID, c.PersonID, SUM(TotalDue) as TotalAmount
    FROM Sales.SalesOrderHeader h 
    JOIN Sales.Customer c on h.CustomerID = c.CustomerID
    WHERE OrderDate>= '2012-07-01' and OrderDate<= '2012-12-31' 
        and c.StoreID IS NULL
    GROUP BY FORMAT(h.OrderDate, 'yyyy-MM'), c.CustomerID, c.PersonID
) s
JOIN Person.Person p on s.PersonID = p.BusinessEntityID
ORDER BY YearMonth, CustomerID

/* -----------------------------------------------------------------------------------------------------------------
2. Practice LEFT (OUTER) JOIN, RIGHT (OUTER) JOIN, FULL OUTER JOIN
*/
-- 2.1. Get list of store customers and their contacts (if any)
-- Step 1: Get list of store customers
SELECT CustomerID, StoreID, PersonID
FROM Sales.Customer 
WHERE StoreID IS NOT NULL

-- Step 2: Count store customers with/without contacts
SELECT COUNT(CustomerID) as NbCustomers,
SUM(CASE WHEN PersonID IS NOT NULL THEN 1 ELSE 0 END) as HaveContact,
SUM(CASE WHEN PersonID IS NULL THEN 1 ELSE 0 END) as DontHaveContact
FROM Sales.Customer 
WHERE StoreID IS NOT NULL

-- Step 3: Get store customer info and contact info (if any)
SELECT CustomerID, StoreID, s.Name as CustomerName, c.PersonID,
CASE WHEN p.BusinessEntityID IS NOT NULL THEN CONCAT(p.FirstName,' ',p.LastName) END as PersonName
FROM Sales.Customer c
JOIN Sales.Store s on c.StoreID = s.BusinessEntityID
LEFT JOIN Person.Person p on c.PersonID = p.BusinessEntityID
WHERE StoreID IS NOT NULL
ORDER BY CustomerID

-- Step 4: Compare with only INNER JOIN. INNER JOIN excludes some customers → incorrect.
SELECT CustomerID, StoreID, s.Name as CustomerName, c.PersonID,
CASE WHEN p.BusinessEntityID IS NOT NULL THEN CONCAT(p.FirstName,' ',p.LastName) END as PersonName
FROM Sales.Customer c
JOIN Sales.Store s on c.StoreID = s.BusinessEntityID
JOIN Person.Person p on c.PersonID = p.BusinessEntityID
WHERE StoreID IS NOT NULL
ORDER BY CustomerID

-- 2.2. Revenue by salespeople in 2011
-- Step 1: Aggregate revenue by SalesPerson, using YEAR(OrderDate) filter
SELECT SalesPersonID, COUNT(SalesOrderID) as NbOrders, SUM(TotalDue) as TotalAmount
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2011
GROUP BY SalesPersonID
ORDER BY SalesPersonID

-- Step 2: Create subquery s and JOIN with SalesPerson to get salesperson info
SELECT sp.BusinessEntityID as SalesPersonID, ISNULL(NbOrders, 0) as NbOrders, ISNULL(TotalAmount, 0) as TotalAmount,
s.SalesPersonID as [SID], sp.BusinessEntityID as SPID
FROM
(SELECT SalesPersonID, COUNT(SalesOrderID) as NbOrders, SUM(TotalDue) as TotalAmount
    FROM Sales.SalesOrderHeader h 
    WHERE YEAR(OrderDate) = 2011
    GROUP BY SalesPersonID
) s 
JOIN Sales.SalesPerson sp on s.SalesPersonID = sp.BusinessEntityID
ORDER BY SalesPersonID

-- Step 3: Switch to RIGHT JOIN
SELECT sp.BusinessEntityID as SalesPersonID, ISNULL(NbOrders, 0) as NbOrders, ISNULL(TotalAmount, 0) as TotalAmount,
s.SalesPersonID as SID, sp.BusinessEntityID as SPID
FROM
(SELECT SalesPersonID, COUNT(SalesOrderID) as NbOrders, SUM(TotalDue) as TotalAmount
    FROM Sales.SalesOrderHeader h 
    WHERE YEAR(OrderDate) = 2011
    GROUP BY SalesPersonID
) s 
RIGHT JOIN Sales.SalesPerson sp on s.SalesPersonID = sp.BusinessEntityID
ORDER BY SalesPersonID

-- Step 4: Switch to FULL OUTER JOIN
SELECT sp.BusinessEntityID as SalesPersonID,
ISNULL(NbOrders, 0) as NbOrders, ISNULL(TotalAmount, 0) as TotalAmount,
s.SalesPersonID as SID, sp.BusinessEntityID as SPID
FROM
(SELECT SalesPersonID, COUNT(SalesOrderID) as NbOrders, SUM(TotalDue) as TotalAmount
    FROM Sales.SalesOrderHeader h 
    WHERE YEAR(OrderDate) = 2011
    GROUP BY SalesPersonID
) s 
FULL OUTER JOIN Sales.SalesPerson sp on s.SalesPersonID = sp.BusinessEntityID

-- Step 5: Add salesperson name
SELECT CASE WHEN sp.BusinessEntityID IS NULL THEN -1 ELSE sp.BusinessEntityID END AS SalesPersonID, 
CASE WHEN sp.BusinessEntityID IS NULL THEN N'Other' ELSE CONCAT(p.FirstName,' ', p.LastName) END AS SalesPersonName,
ISNULL(NbOrders, 0) AS NbOrders, 
ISNULL(TotalAmount, 0) AS TotalAmount
FROM
(SELECT SalesPersonID, COUNT(SalesOrderID) as NbOrders, SUM(TotalDue) as TotalAmount
    FROM Sales.SalesOrderHeader
    WHERE YEAR(OrderDate) = 2011
    GROUP BY SalesPersonID
) s 
FULL OUTER JOIN Sales.SalesPerson sp ON s.SalesPersonID = sp.BusinessEntityID
LEFT JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
ORDER BY SalesPersonID

/* -----------------------------------------------------------------------------------------------------------------
3. Practice CROSS JOIN, SELF JOIN
*/
-- 3.1. Get revenue by territory and category in 2011. If no revenue exists, default to 0.
-- Step 1: CROSS JOIN SalesTerritory and ProductCategory to list all category-territory pairs
SELECT st.TerritoryID, st.Name as TerritoryName, pc.ProductCategoryID, pc.Name as ProductCategoryName
FROM Sales.SalesTerritory st 
CROSS JOIN Production.ProductCategory pc
ORDER BY TerritoryID, ProductCategoryID

-- Step 2: Aggregate revenue by territory and category
SELECT TerritoryID, c.ProductCategoryID, SUM(TotalDue) as TotalAmount 
FROM Sales.SalesOrderHeader h 
JOIN Sales.SalesOrderDetail d on h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p on d.ProductID = p.ProductID
JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
WHERE YEAR(OrderDate) = 2011
GROUP BY TerritoryID, c.ProductCategoryID

-- Step 3: Create subquery s (Step 2 result). LEFT JOIN with Step 1 results to include all pairs. Use ISNULL for default 0.
SELECT st.TerritoryID, st.Name as TerritoryName, pc.ProductCategoryID, pc.Name as ProductCategoryName, ISNULL(TotalAmount, 0) as TotalAmount
FROM Sales.SalesTerritory st 
CROSS JOIN Production.ProductCategory pc
LEFT JOIN 
(SELECT TerritoryID, c.ProductCategoryID, SUM(TotalDue) as TotalAmount 
    FROM Sales.SalesOrderHeader h 
    JOIN Sales.SalesOrderDetail d on h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p on d.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sc on p.ProductSubcategoryID = sc.ProductSubcategoryID
    JOIN Production.ProductCategory c on sc.ProductCategoryID = c.ProductCategoryID
    WHERE YEAR(OrderDate) = 2011
    GROUP BY TerritoryID, c.ProductCategoryID
) s on pc.ProductCategoryID = s.ProductCategoryID and st.TerritoryID = s.TerritoryID
ORDER BY TerritoryID, ProductCategoryID

-- 3.2. Get regions in the same country as TerritoryID = 1 (excluding itself)
SELECT t2.TerritoryID, t2.Name as TerritoryName, t2.CountryRegionCode
FROM Sales.SalesTerritory t1
JOIN Sales.SalesTerritory t2 on t1.CountryRegionCode = t2.CountryRegionCode
WHERE t1.TerritoryID = 1 and t2.TerritoryID <> 1

/* -----------------------------------------------------------------------------------------------------------------
4. Practice UNION, UNION ALL, INTERSECT, EXCEPT
*/
-- 4.1. Get customers who purchased in June 2013 or July 2013
-- Step 1: Customers who purchased in June 2013
SELECT h.CustomerID
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE c.StoreID IS NULL and OrderDate BETWEEN '2013-06-01' AND '2013-06-30'
GROUP BY h.CustomerID

-- Step 2: Customers who purchased in July 2013
SELECT h.CustomerID
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE c.StoreID IS NULL and OrderDate BETWEEN '2013-07-01' AND '2013-07-31'
GROUP BY h.CustomerID

-- Step 3: Use UNION to combine both sets
SELECT h.CustomerID 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE c.StoreID IS NULL and OrderDate BETWEEN '2013-06-01' AND '2013-06-30'
GROUP BY h.CustomerID
UNION
SELECT h.CustomerID 
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE c.StoreID IS NULL and OrderDate BETWEEN '2013-07-01' AND '2013-07-31'
GROUP BY h.CustomerID

-- 4.2. Customers who purchased in June 2013 and also in July 2013
SELECT h.CustomerID -- July 2013 customers
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE c.StoreID IS NULL and OrderDate BETWEEN '2013-07-01' AND '2013-07-31'
GROUP BY h.CustomerID
INTERSECT
SELECT h.CustomerID -- June 2013 customers
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c on h.CustomerID = c.CustomerID
WHERE c.StoreID IS NULL and OrderDate BETWEEN '2013-
