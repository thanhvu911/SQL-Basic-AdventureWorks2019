-- 1
-- customer with id 11000
SELECT CustomerID, PersonID, StoreID, TerritoryID, PersonType, FirstName, MiddleName, LastName, Name, SalesPersonID, pbe.*
FROM Sales.Customer sc
LEFT JOIN Person.Person pp on sc.PersonID = pp.BusinessEntityID
LEFT JOIN Sales.Store ss on sc.StoreID = ss.BusinessEntityID
LEFT JOIN Person.BusinessEntity pbe on sc.TerritoryID = pbe.BusinessEntityID
WHERE sc.CustomerID = 11000

--2 
-- customer with id 29484
SELECT CustomerID, PersonID, StoreID, TerritoryID, PersonType, FirstName, MiddleName, LastName, Name, SalesPersonID, PersonType
FROM Sales.Customer sc
LEFT JOIN Person.Person pp on sc.PersonID = pp.BusinessEntityID
LEFT JOIN Sales.Store ss on sc.StoreID = ss.BusinessEntityID
WHERE sc.CustomerID = 29484

-- sale person for customer with id 29484
SELECT BusinessEntityID, PersonType, FirstName,MiddleName, LastName
FROM Person.Person
WHERE BusinessEntityID = 279

--3
-- sales store id with sales person id 279
SELECT BusinessEntityID AS StoreID, Name AS StoreName
FROM Sales.Store
WHERE SalesPersonID = 279
ORDER BY StoreID ASC

--4 
-- store list in US and CANADA
SELECT CustomerID, sc.TerritoryID, StoreID
FROM Sales.Customer sc
LEFT JOIN Sales.SalesTerritory sst on sc.TerritoryID = sst.TerritoryID
WHERE sst.CountryRegionCode IN ('US','CA') AND StoreID IS NOT NULL

--5
-- top 5 most valuable order in 2011, 2012 of customers 29624, 29861, 29880
SELECT TOP(5) SalesOrderID, CustomerID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) IN (2011,2012) AND CustomerID IN (29624, 29861, 29880)
ORDER BY TotalDue DESC

--6
-- supervisor gender male and hireyear 2008 
SELECT BusinessEntityID AS EmployeeID, JobTitle, BirthDate, DATEDIFF(YEAR,BirthDate,GETDATE()) AS Age, Gender, HireDate 
FROM HumanResources.Employee
WHERE Gender = 'M' AND YEAR(HireDate) = 2008 AND JobTitle LIKE '%Supervisor%'

--7
-- list of products Bikes (ProductCategoryID=1) and Clothing (ProductCategoryID=3).
SELECT sps.ProductCategoryID, ProductSubcategoryID, sps.Name AS ProductSubcategoryName
FROM Production.ProductSubcategory sps
LEFT JOIN Production.ProductCategory spc on sps.ProductCategoryID = spc.ProductCategoryID 
WHERE spc.ProductCategoryID IN (1,3)
ORDER BY sps.ProductCategoryID, ProductSubcategoryID

--8 
-- calculate the total sales of products that is white or black, and size s,m,l or xl
SELECT ppod.ProductID, ppod.PurchaseOrderID, ppod.PurchaseOrderDetailID, ppod.DueDate,ppod.OrderQty,ppod.UnitPrice,ppod.LineTotal,
(ppod.OrderQty * ppod.UnitPrice) AS LinePurchaseAmount 
FROM Purchasing.PurchaseOrderDetail ppod
JOIN Production.Product pp ON ppod.ProductID = pp.ProductID
WHERE pp.Color IN ('White','Black') AND pp.Size IN ('S','M','L','XL')
ORDER BY ProductID, PurchaseOrderID, PurchaseOrderDetailID