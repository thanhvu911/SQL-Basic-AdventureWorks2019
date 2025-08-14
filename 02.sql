USE AdventureWorks2019
GO

/* -----------------------------------------------------------------------------------------------------------------
Step 1: Practice aggregate functions
*/
-- 1.1. Get the smallest product ID, the largest product ID, and the total number of products
SELECT MIN(ProductID) as MinProductID, MAX(ProductID) as MaxProductID, COUNT(ProductID) as NbProducts
FROM Production.Product

-- 1.2. Count the number of products with color White, Black, or Red
SELECT COUNT(ProductID) as NbProducts
FROM Production.Product
WHERE Color='WHITE' or Color='BLACK' or Color='RED'

/* -- 1.3. Get sales information in 2011 for regions in the US or Canada 
(corresponding to TerritoryID = 1,2,3,4,5,6)
+ number of orders, first order date, last order date
+ total merchandise value, total tax amount, total freight amount, total amount of all orders
+ smallest and largest order value, average order value
+ calculate average order value manually = total amount of all orders / number of orders
*/ 
SELECT COUNT(SalesOrderID) as NbOrders, MIN(OrderDate) as MinOrderDate, MAX(OrderDate) as MaxOrderDate,
SUM(SubTotal) as SubTotal, SUM(TaxAmt) as TaxAmount, SUM(Freight) as Freight, SUM(TotalDue) as TotalAmount,
MIN(TotalDue) as MinOrderAmount, MAX(TotalDue) as MaxOrderAmount, AVG(TotalDue) as AvgOrderAmount,
ROUND(SUM(TotalDue) / NULLIF(COUNT(SalesOrderID), 0), 2) as CalcAvgOrderAmount
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2011 and TerritoryID in (1,2,3,4,5,6)

/* -----------------------------------------------------------------------------------------------------------------
Step 2: Practice SQL GROUP BY with aggregate functions
*/
-- 2.1. Get total sales, smallest and largest order value for each year. Sort by year in ascending order.
SELECT YEAR(OrderDate) as [Year], SUM(TotalDue) as TotalAmount, MIN(TotalDue) as MinOrderAmount, MAX(TotalDue) as MaxOrderAmount
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY YEAR(OrderDate)
--ORDER BY 1

/* -- 2.2. Get sales information by product. Round to 2 decimal places.
+ total revenue, total quantity sold, lowest and highest selling price
+ number of orders per product
+ average quantity sold per order */
SELECT ProductID,
ROUND(SUM(LineTotal), 2) as TotalAmount, SUM(OrderQty) as TotalQuantity, 
ROUND(MIN(UnitPrice), 2) AS MinUnitPrice, ROUND(MAX(UnitPrice), 2) AS MaxUnitPrice,
--ROUND(MIN(UnitPrice * (1 - UnitPriceDiscount)), 2) as MinUnitPrice, ROUND(MAX(UnitPrice * (1 - UnitPriceDiscount)), 2) as MaxUnitPrice, 
COUNT(DISTINCT SalesOrderID) as NbOrders, 
ROUND(SUM(OrderQty) * 1.0 / NULLIF(COUNT(DISTINCT SalesOrderID), 0), 2) as AvgQuantityPerOrder
FROM Sales.SalesOrderDetail
GROUP BY ProductID
ORDER BY ProductID

/* -----------------------------------------------------------------------------------------------------------------
Step 3: Practice SQL GROUP BY with HAVING
*/

-- 3.1. Get sales information for products with total quantity sold over 5000.
SELECT ProductID,
ROUND(SUM(LineTotal), 2) as TotalAmount, SUM(OrderQty) as TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY ProductID
HAVING SUM(OrderQty) > 5000
ORDER BY ProductID

-- 3.2. Check if there is duplicate data
SELECT SalesOrderID, COUNT(*) as NbRows
FROM Sales.SalesOrderDetail 
GROUP BY SalesOrderID 
HAVING COUNT(*) > 1
ORDER BY NbRows DESC
-- ORDER BY 2 DESC

-- 3.3. Get the list of order IDs in the order detail table
SELECT DISTINCT SalesOrderID FROM Sales.SalesOrderDetail ORDER BY 1
SELECT SalesOrderID FROM Sales.SalesOrderDetail GROUP BY SalesOrderID ORDER BY SalesOrderID

/* -----------------------------------------------------------------------------------------------------------------
Step 4: Practice SQL CASE WHEN
*/
/* -- 4.1. Classify orders by order value.
If the order value >= $100,000 → label 'High'
If the order value >= $10,000 and < $100,000 → label 'Medium'
If the order value < $10,000 → label 'Low'
*/
SELECT SalesOrderID, TotalDue, 
CASE WHEN TotalDue >= POWER(10, 5) THEN 'High'
WHEN TotalDue >= POWER(10,4) THEN 'Medium'
ELSE 'Low' END as [Type]
FROM Sales.SalesOrderHeader
ORDER BY SalesOrderID

-- 4.2. Count number of orders in each category
SELECT Type, COUNT(SalesOrderID) as NbOrders
FROM
(SELECT SalesOrderID, TotalDue, 
    CASE WHEN TotalDue >= POWER(10, 5) THEN 'High'
    WHEN TotalDue >= POWER(10,4) THEN 'Medium'
    ELSE 'Low' END as [Type]
    FROM Sales.SalesOrderHeader
) r
GROUP BY [Type]
ORDER BY NbOrders

/* -----------------------------------------------------------------------------------------------------------------
Step 5: Practice basic mathematical functions (SQL Mathematical Functions)
*/
-- 5.1. Power, square root
SELECT POWER(10, 3) as [10^3], SQRT(10.3) as [Square root of 10.3], EXP(3) as [e^3], LOG(8, 2) as [Log base 2 of 8], LOG10(1000) as [Log base 10 of 1000]

-- 5.2. Rounding numbers
SELECT PI() as [Original number], ROUND(PI(), 2) as [Round to 2 decimals], ROUND(PI(), 3) as [Round to 3 decimals]

-- 5.3. Distance between two points A(3, 4) and B(5, 6)
SELECT SQRT( POWER(5-3, 2) + POWER(6-4, 2) ) as [d(A,B)]

-- 5.4. Area of a circle with radius 5 cm
SELECT PI() * POWER(5, 2) as [cm^2]

-- 5.5. Cluster orders by order value using log
SELECT SalesOrderID, TotalDue, FLOOR(LOG10(TotalDue)) as [Type]
FROM Sales.SalesOrderHeader

-- 5.6. Count number of orders in each cluster
SELECT Type, COUNT(SalesOrderID) as NbOrders, CONCAT(N'Order value from ', POWER(10, [Type]-1) ,N' to ', POWER(10, [Type])) as [Description]
FROM
(SELECT SalesOrderID, TotalDue, CEILING(LOG10(TotalDue)) as [Type]
    FROM Sales.SalesOrderHeader
) r
GROUP BY [Type]
ORDER BY [Type]

/* -----------------------------------------------------------------------------------------------------------------
Step 6: Practice basic string functions (SQL String Functions)
*/
-- 6.1. Concatenate strings, get string length, first 4 characters, last 3 characters, lowercase, uppercase
SELECT CONCAT(N'Course',' ',N'SQL Hero') as [Course name], 
    LEN(N'SQL Hero Course') as [String length], 
    LEFT(N'Course', 4) as [First 4 characters], RIGHT(N'Course', 3) as [Last 3 characters],
    LOWER(N'SQL Hero Course') as [Lowercase], UPPER(N'SQL Hero Course') as [Uppercase]

-- 6.2. Count products starting with 'Hex'
SELECT COUNT(ProductID) as [NbProducts]
FROM Production.Product
WHERE LEFT(Name, LEN('Hex')) = 'Hex'

-- 6.3. Get list of individual customers
SELECT BusinessEntityID, PersonType, NameStyle, FirstName, MiddleName, LastName,
CASE WHEN NameStyle = 0 THEN CONCAT(FirstName,' ', MiddleName,' ',LastName) -- Western style
WHEN NameStyle = 1 THEN CONCAT(LastName,' ', MiddleName,' ',FirstName) -- Eastern style
END as FullName 
FROM Person.Person
WHERE PersonType = 'IN' -- and NameStyle = 1

/* -----------------------------------------------------------------------------------------------------------------
Step 7: Practice basic date/datetime functions (SQL Date Functions)
*/
-- 7.1. Get current date/time
SELECT GETDATE() as [Current datetime]

-- 7.2. Extract year, month, day (as numbers)
SELECT YEAR('2020-08-15') as [Year], MONTH('2020-08-15') as [Month], DAY('2020-08-15') as [Day]

-- 7.3. Format date/time as desired (return as string)
SELECT FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss') as [Year-Month-Day Hour:Minute:Second], 
FORMAT(GETDATE(), 'yyyy-MM') as [Year-Month], 
FORMAT(GETDATE(), 'yyyy-MM-dd') as [Date], FORMAT(GETDATE(), 'dd/MM/yyyy') as [Date], 
FORMAT(GETDATE(), 'HH:mm:ss') as [Hour:Minute:Second]

-- 7.4. Calculate difference in days, months, quarters, years between two dates
SELECT DATEDIFF(DAY, '2020-08-15', GETDATE()) as [Days since 15/08/2020], 
DATEDIFF(MONTH, '2020-08-15', GETDATE()) as [Months since 15/08/2020],
DATEDIFF(YEAR, '2020-08-15', GETDATE()) as [Years since 15/08/2020]

-- 7.5. Yesterday, tomorrow, first day of month, last day of month, first day of previous month, last day of previous month
SELECT DATEADD(DAY, -1, '2020-08-15') as [Yesterday], DATEADD(DAY, 1, '2020-08-15') as [Tomorrow],
DATEADD(MONTH, DATEDIFF(MONTH, 0, '2020-08-15'), 0) as [First day of month], 
EOMONTH('2020-08-15') as [Last day of month],
DATEADD(MONTH, DATEDIFF(MONTH, 0, '2020-08-15') - 1, 0) as [First day of previous month], 
DATEADD(MONTH, DATEDIFF(MONTH, 0, '2020-08-15'), -1) as [Last day of previous month]

/*
-- 7.6. Get sales information for the previous month, assuming current date is 15/08/2011
+ number of orders, total merchandise value, total tax amount, total freight amount, total amount of all orders
+ smallest and largest order value, average order value
*/
SELECT COUNT(SalesOrderID) as NbOrders,
SUM(SubTotal) as SubTotal, SUM(TaxAmt) as TaxAmount, SUM(Freight) as Freight, SUM(TotalDue) as TotalAmount,
MIN(TotalDue) as MinOrderAmount, MAX(TotalDue) as MaxOrderAmount, AVG(TotalDue) as AvgOrderAmount
FROM Sales.SalesOrderHeader
WHERE OrderDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, '2011-08-15') - 1, 0)
    and OrderDate <=  DATEADD(MONTH, DATEDIFF(MONTH, 0, '2011-08-15'), -1)
