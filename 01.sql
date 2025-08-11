-- 1.1. Get all product information produced/sold
SELECT * FROM Production.Product;

-- Get the first 100 products (default order)
SELECT TOP(100) * FROM Production.Product;

-- 1.2. Get the first 100 products ordered by name including the fields:
-- Product ID, Product Number, Product Name, Color, Size, Weight, Class, Style
SELECT TOP(100) ProductID, ProductNumber, Name AS ProductName, Color, Size, Weight, Class, Style
FROM Production.Product
ORDER BY Name;

-- 1.3. What color types do the products produced/sold by the company have?
SELECT DISTINCT Color 
FROM Production.Product 
WHERE Color IS NOT NULL 
ORDER BY Color;

-- Get all sales order information
SELECT * FROM Sales.SalesOrderHeader;

-- Get the first 100 sales orders (default order)
SELECT TOP(100) * FROM Sales.SalesOrderHeader;

-- 1.4. Get sales order information including:
-- Sales Order ID, Sales Order Number, Purchase Order Number, Order Date, Due Date, Ship Date,
-- Customer ID, Salesperson ID, Territory ID, Subtotal, Tax Amount, Freight, Total Due
SELECT SalesOrderID, SalesOrderNumber, PurchaseOrderNumber, 
       OrderDate, DueDate, ShipDate, 
       CustomerID, SalesPersonID, TerritoryID,
       SubTotal, TaxAmt, Freight, TotalDue
FROM Sales.SalesOrderHeader;

-- Get all sales order detail information
SELECT * FROM Sales.SalesOrderDetail;

-- Get the first 100 sales order detail lines (default order)
SELECT TOP(100) * FROM Sales.SalesOrderDetail;

-- 1.5. Get sales order detail information including:
-- Sales Order ID, Sales Order Detail ID, Product ID, Quantity, Unit Price, Discount %, Line Total
-- Rename column OrderQty to Quantity
SELECT SalesOrderID, SalesOrderDetailID, ProductID, OrderQty AS Quantity, UnitPrice, UnitPriceDiscount, LineTotal
FROM Sales.SalesOrderDetail AS d
ORDER BY SalesOrderID, SalesOrderDetailID;

-----------------------------------------------------------------------------------------------------------------
-- Step 2: Practice SQL WHERE with comparison operators

-- 2.1. List of products with white color
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style 
FROM Production.Product
WHERE Color = 'WHITE';

-- 2.2. List of sales orders placed on 2011-05-31
SELECT SalesOrderID, OrderDate, CustomerID 
FROM Sales.SalesOrderHeader
WHERE OrderDate = '2011-05-31'
ORDER BY SalesOrderID;

-- 2.3. List of orders from customer ID = 29491 placed in 2011, ordered by date
SELECT SalesOrderID, OrderDate, CustomerID 
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2011 AND CustomerID = 29491
ORDER BY OrderDate;

-- 2.4. List of orders placed in June 2011, ordered by date and customer ID
-- Method 1
SELECT SalesOrderID, OrderDate, CustomerID 
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2011-06-01' AND OrderDate <= '2011-06-30'
ORDER BY OrderDate, CustomerID;

-- Method 2
SELECT SalesOrderID, OrderDate, CustomerID 
FROM Sales.SalesOrderHeader
WHERE OrderDate BETWEEN '2011-06-01' AND '2011-06-30'
ORDER BY OrderDate, CustomerID;

-- Method 3
SELECT SalesOrderID, OrderDate, CustomerID
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2011 AND MONTH(OrderDate) = 6 
ORDER BY OrderDate, CustomerID;

-- 2.5. List of orders with Subtotal > 30000 in 2012 excluding December
SELECT OrderDate, SalesOrderID, SubTotal
FROM Sales.SalesOrderHeader 
WHERE SubTotal > 30000 
  AND YEAR(OrderDate) = 2012 
  AND MONTH(OrderDate) <> 12
ORDER BY OrderDate, SalesOrderID;

-----------------------------------------------------------------------------------------------------------------
-- Step 3: Practice SQL WHERE with logical operators

-- 3.1. List of products with color white, black, or red
-- Method 1
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style
FROM Production.Product
WHERE Color = 'WHITE' OR Color = 'BLACK' OR Color = 'RED';

-- Method 2
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style
FROM Production.Product
WHERE Color IN ('WHITE','BLACK','RED');

-- 3.2. List of products with color white and size S, M, L, or XL
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style 
FROM Production.Product
WHERE Color = 'WHITE' AND Size IN ('S','M','L','XL');

-- 3.3. List of products with (color white and size L) or (color black and size XL)
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style 
FROM Production.Product
WHERE (Color = 'WHITE' AND Size = 'L') 
   OR (Color = 'BLACK' AND Size = 'XL')
ORDER BY ProductID;

-- 3.4. Get products whose names contain 'Sport', ordered by product ID
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style 
FROM Production.Product
WHERE Name LIKE '%Sport%'
ORDER BY ProductID;

-- 3.5. Get products that have both color and size values
SELECT ProductID, ProductNumber, Name, Color, Size, Weight, Class, Style 
FROM Production.Product
WHERE Color IS NOT NULL AND Size IS NOT NULL;

-----------------------------------------------------------------------------------------------------------------
-- Step 4: Practice arithmetic operators

-- 4.1. Calculate total sales amount for order 43898:
-- Formula: TotalSalesAmount = SubTotal + TaxAmt + Freight
-- Compare with TotalDue
SELECT SalesOrderID, SubTotal, TaxAmt, Freight, TotalDue,
       SubTotal + TaxAmt + Freight AS TotalSalesAmount
FROM Sales.SalesOrderHeader
WHERE SalesOrderID = 43898;

-- 4.2. Calculate line sales amount for each order line in order 43898:
-- Formula: LineSalesAmount = OrderQty * UnitPrice * (1 - UnitPriceDiscount)
SELECT SalesOrderID, SalesOrderDetailID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount, LineTotal,
       OrderQty * UnitPrice * (1 - UnitPriceDiscount) AS LineSalesAmount
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = 43898
ORDER BY ProductID;
