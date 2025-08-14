-- 1. Calculate the number of managers by birth year (JobTitle contains 'Manager'), sorted by birth year descending.
SELECT YEAR(BirthDate) AS Year, COUNT(*) AS NbOfPeople
FROM HumanResources.Employee
WHERE JobTitle LIKE '%Manager%'
GROUP BY YEAR(BirthDate)
ORDER BY YEAR(BirthDate) DESC

-- 2. Retrieve the list of salespeople with a FullName column (FirstName + MiddleName + LastName), sorted by FullName ascending.
-- Special case middlename is null
SELECT BusinessEntityID, PersonType, NameStyle, FirstName, MiddleName, LastName, 
CASE WHEN NameStyle = 0 AND MiddleName IS NOT NULL THEN CONCAT(FirstName,' ',MiddleName,' ',LastName) 
WHEN NameStyle = 1 AND MiddleName IS NOT NULL THEN CONCAT(FirstName,' ',MiddleName,' ',LastName)
WHEN NameStyle = 0 AND MiddleName IS NULL THEN CONCAT(FirstName,' ',LastName) 
WHEN NameStyle = 1 AND MiddleName IS NOT NULL THEN CONCAT(FirstName,' ',LastName)
END AS FullName
FROM Person.Person
WHERE PersonType = 'SP'

-- 3. Calculate the volume of a sphere with radius 8 cm, rounded to 3 decimal places.
SELECT ROUND( 4/3 * PI() * POWER(8,3), 3) AS [cm^3]

-- 4. Get the top 5 customers from the US or Canada with the highest total order value 
--    in the last 7 days, using 2013-08-15 as the current date.
SELECT TOP(5)CustomerID, SUM(TotalDue) AS TotalAmount
FROM Sales.SalesOrderHeader ssoh
LEFT JOIN Sales.SalesTerritory sst ON ssoh.TerritoryID = sst.TerritoryID
WHERE OrderDate >= DATEADD(DAY,-7,'2013-08-15') AND OrderDate <= '2013-08-15'  AND sst.CountryRegionCode IN ('US','CA')
GROUP BY CustomerID
ORDER BY TotalAmount DESC

-- 5. Retrieve the list of orders that contain only one product.
SELECT SalesOrderID, MIN(ProductID) AS ProductID,
SUM(LineTotal) AS TotalAmount, SUM(OrderQty) AS TotalAmount
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING COUNT(ProductID) = 1
ORDER BY SalesOrderID

-- 6. Calculate the revenue of regions in the US or Canada and their percentage share 
--    of the total system revenue for each year.
WITH revenue_region AS (
	SELECT YEAR(OrderDate) AS [Year],
	SUM(CASE WHEN sst.CountryRegionCode IN ('US','CA') THEN TotalDue ELSE 0 END) AS SalesAmount,
	SUM(TotalDue) AS TotalAmount
	FROM Sales.SalesOrderHeader ssoh
	LEFT JOIN Sales.SalesTerritory sst ON ssoh.TerritoryID = sst.TerritoryID
	GROUP BY YEAR(OrderDate)
)

SELECT *, Round((SalesAmount/TotalAmount),2) AS Ratio
FROM revenue_region
ORDER BY Year

-- 7. Retrieve sales information for products that have never changed their selling price.
SELECT ProductID, Sum(LineTotal) AS TotalAmount, SUM(OrderQty) AS TotalQuantity, MIN(UnitPrice) AS MinUnitPrice, MAX(UnitPrice) AS MaxUnitPrice
FROM Sales.SalesOrderDetail
GROUP BY ProductID
HAVING MIN(UnitPrice) = MAX(UnitPrice)
ORDER BY ProductID

-- 8. Retrieve the list of customers, number of orders, total sales, and average order value 
--    for the past 365 days from 2013-08-15, including only customers with at least 2 orders, 
--    sorted by total sales descending and CustomerID ascending.

SELECT CustomerID, COUNT(*) AS NbOrders, ROUND(SUM(TotalDue),2) AS TotalAmount, ROUND(AVG(TotalDue),2) AS AvgOrderAmount
FROM Sales.SalesOrderHeader
WHERE OrderDate >= DATEADD(DAY,-365,'2013-08-15') AND OrderDate <= '2013-08-15'
GROUP BY CustomerID
HAVING COUNT(*) >= 2
ORDER BY TotalAmount DESC