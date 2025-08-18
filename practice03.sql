/* Question 1
Requirement: Calculate the total revenue of each month in 2012 for two product groups: 
 - Products manufactured by the company
 - Products imported for resale
Data sources: Sales.SalesOrderHeader, Sales.SalesOrderDetail, Production.Product
*/

SELECT FORMAT(ssoh.OrderDate,'yyyy-MM') AS YearMonth,EOMONTH(ssoh.OrderDate) AS EndDateOfMonth, 
SUM(CASE WHEN pp.MakeFlag = 1 THEN LineTotal ELSE 0 END) AS ManufacturedSalesAmount,
SUM(CASE WHEN pp.MakeFlag = 0 THEN LineTotal ELSE 0 END) AS PurhcasedSalesAmount,
SUM(LineTotal) AS SalesAmount
FROM Sales.SalesOrderHeader ssoh
JOIN Sales.SalesOrderDetail ssod ON ssoh.SalesOrderID = ssod.SalesOrderID
JOIN Production.Product pp ON ssod.ProductID = pp.ProductID
WHERE YEAR(ssoh.OrderDate) = 2012
GROUP BY FORMAT(ssoh.OrderDate,'yyyy-MM'), EOMONTH(ssoh.OrderDate)
ORDER BY YearMonth, EndDateOfMonth

/* Question 2
Requirement: Calculate the number of purchase orders and the total amount payable 
for each vendor from January to June 2012. Sort by VendorID ascending.
Data sources: Purchasing.PurchaseOrderHeader, Purchasing.Vendor
*/
SELECT ppoh.VendorID, pv.Name AS VendorName, COUNT(*) AS NbPurchaseOrders, SUM(TotalDue) AS PurchaseAmount 
FROM Purchasing.PurchaseOrderHeader ppoh
LEFT JOIN Purchasing.Vendor pv ON ppoh.VendorID = pv.BusinessEntityID
WHERE YEAR(OrderDate) = 2012 AND (MONTH(OrderDate) BETWEEN 1 AND 6)
GROUP BY ppoh.VendorID, pv.Name
ORDER BY ppoh.VendorID

/* Question 3
Requirement: Calculate the total import cost for each month in 2012. 
Only include items imported for resale (not manufactured by the company).
Data sources: Purchasing.PurchaseOrderHeader, Purchasing.PurchaseOrderDetail, Production.Product
*/
SELECT * FROM Purchasing.PurchaseOrderHeader
SELECT * FROM Purchasing.PurchaseOrderDetail
SELECT * FROM Production.Product

SELECT FORMAT(ppoh.OrderDate,'yyyy-MM') AS YearMonth,EOMONTH(ppoh.OrderDate) AS EndDateOfMonth,
SUM(CASE WHEN pp.MakeFlag = 0 AND pp.FinishedGoodsFlag = 1 THEN LineTotal ELSE 0 END) AS PurchaseAmount
FROM Purchasing.PurchaseOrderHeader ppoh
JOIN Purchasing.PurchaseOrderDetail ppod ON ppoh.PurchaseOrderID = ppod.PurchaseOrderID
JOIN Production.Product pp ON ppod.ProductID = pp.ProductID
WHERE YEAR(ppoh.OrderDate) = 2012
GROUP BY FORMAT(ppoh.OrderDate,'yyyy-MM'), EOMONTH(ppoh.OrderDate)
ORDER BY YearMonth, EndDateOfMonth

/* Question 4
Requirement: Classify products based on supplier return rate:
 - >= 5% → High return rate
 - 2% to < 5% → Medium return rate
 - 0.5% to < 2% → Low return rate
 - < 0.5% → Very low return rate
Data sources: Purchasing.PurchaseOrderDetail, Production.Product
*/
WITH RejectedRatio AS (
	SELECT ppod.ProductID, pp.Name AS ProductName, SUM(ppod.ReceivedQty) AS ReceivedQty, SUM(ppod.RejectedQty) AS RejectedQty, (SUM(ppod.RejectedQty) / SUM(ppod.ReceivedQty)) AS RejectedRatio
	FROM Purchasing.PurchaseOrderDetail ppod
	LEFT JOIN Production.Product pp ON ppod.ProductID = pp.ProductID
	GROUP BY ppod.ProductID, pp.Name
)
SELECT *, 
CASE 
	WHEN RejectedRatio >= 0.05 THEN 'High return rate'
	WHEN RejectedRatio < 0.05 AND RejectedRatio >= 0.02 THEN 'Medium return rate'
	WHEN RejectedRatio < 0.02 AND RejectedRatio >= 0.005 THEN 'Low return rate'
	ELSE 'Very low return rate'
END AS Class
FROM RejectedRatio
ORDER BY ProductID

/* Question 5
Requirement: Get the list of vendors who use both shipping methods 
'OVERSEAS - DELUXE' and 'OVERNIGHT J-FAST'.
Data sources: Purchasing.PurchaseOrderHeader, Purchasing.ShipMethod
*/

SELECT VendorID
FROM Purchasing.PurchaseOrderHeader ppoh
LEFT JOIN Purchasing.ShipMethod psm ON ppoh.ShipMethodID = psm.ShipMethodID
WHERE psm.Name IN ('OVERSEAS - DELUXE') 
GROUP BY VendorID
INTERSECT
SELECT VendorID
FROM Purchasing.PurchaseOrderHeader ppoh
LEFT JOIN Purchasing.ShipMethod psm ON ppoh.ShipMethodID = psm.ShipMethodID
WHERE psm.Name IN ('OVERNIGHT J-FAST') 
GROUP BY VendorID

/* Question 6
Requirement: Get the set of newly imported products in 2013.
Data sources: Purchasing.PurchaseOrderHeader, Purchasing.PurchaseOrderDetail
*/
SELECT ProductID
FROM Purchasing.PurchaseOrderHeader ppoh
JOIN Purchasing.PurchaseOrderDetail ppod ON ppoh.PurchaseOrderID = ppod.PurchaseOrderID
WHERE YEAR(OrderDate) = 2013
GROUP BY ProductID

EXCEPT

SELECT ProductID
FROM Purchasing.PurchaseOrderHeader ppoh
JOIN Purchasing.PurchaseOrderDetail ppod ON ppoh.PurchaseOrderID = ppod.PurchaseOrderID
WHERE YEAR(OrderDate) < 2013
GROUP BY ProductID

/* Question 7
Requirement: Get the list of production materials being imported from at least 3 vendors. 
The latest receipt date must be within the last 6 months from the reference date '2011-12-01'.
Data sources: Purchasing.ProductVendor, Production.Product
*/
SELECT pv.ProductID, p.ProductNumber, p.Name AS ProductName, p.Color
FROM Purchasing.ProductVendor pv
LEFT JOIN Production.Product p ON pv.ProductID = p.ProductID
WHERE LastReceiptDate < '2011-12-01' AND LastReceiptDate > DATEADD(MONTH,-6,'2011-12-01') 
GROUP BY pv.ProductID, p.ProductNumber, p.Name, p.Color
HAVING COUNT(DISTINCT BusinessEntityID) >= 3
ORDER BY ProductID

/* Question 8 (*)
Requirement: Get vendor information for the best purchase price of production materials. 
Consider only the materials being imported from at least 3 vendors (from Question 7).
Data sources: Purchasing.ProductVendor, Production.Product

Advanced: After getting the result, create a new column Note using STRING_AGG() and CONCAT() 
to summarize data by ProductID.
*/
SELECT * FROM Purchasing.Vendor
SELECT * FROM Purchasing.ProductVendor
SELECT * FROM Production.Product

SELECT pv.ProductID, p.Name AS ProductName,pv.BusinessEntityID, v.Name AS VendorName, MinUnitCost
FROM Purchasing.ProductVendor pv
JOIN (
    SELECT pv.ProductID, COUNT(BusinessEntityID) AS NbVendors, MIN(LastReceiptCost) AS MinUnitCost,
    STRING_AGG(CONCAT('{v:', BusinessEntityID, ',c:', LastReceiptCost, '}'), ',') AS Note
    FROM Purchasing.ProductVendor pv
    JOIN Production.Product p ON pv.ProductID = p.ProductID
    WHERE p.FinishedGoodsFlag = 0 
    GROUP BY pv.ProductID
    HAVING COUNT(BusinessEntityID) >= 3
) pp ON pv.ProductID = pp.ProductID AND pv.LastReceiptCost = pp.MinUnitCost
LEFT JOIN Production.Product p ON pv.ProductID = p.ProductID
LEFT JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
ORDER BY pv.ProductID, pv.BusinessEntityID;
