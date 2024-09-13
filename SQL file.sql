CREATE DATABASE ACADIA;
USE ACADIA;

CREATE TABLE Sales (
    CustomerID VARCHAR(255),
    OrderID VARCHAR(255),
    Sales FLOAT,
    TransactionDate DATE
);

CREATE TABLE Returns (
    CustomerID VARCHAR(255),
    ReturnDate DATE,
    ReturnSales FLOAT,
    OrderID VARCHAR(255)
);

Select count(*) from Sales;
Select * from Returns;

Select @@secure_file_priv;

LOAD DATA INFILE 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\Sales.CSV' 
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA INFILE 'C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\Returns.CSV' 
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

Select customerid, orderid, count(*)
from sales
group by customerid, orderid
having count(*)>1;

CREATE TABLE temp_table AS
SELECT DISTINCT *
FROM sales;

DROP TABLE sales;
DROP table returns;

RENAME TABLE temp_table TO sales;


Select count(*) from sales;
Select count(*) from returns;








-- A] What % of sales result in a return?

SELECT 
ROUND((COUNT(DISTINCT r.OrderID) * 100 / COUNT(DISTINCT s.OrderID)),2) as Return_Percentage
FROM Sales s
LEFT JOIN Returns r 
ON s.OrderID = r.OrderID;
 
Select 
ROUND(SUM(r.ReturnSales)*100/SUM(s.SALES),2) as Return_Percentage
from Sales s
LEFT JOIN Returns r
on s.OrderID = r.OrderID;



-- B) What % of returns are full returns?

SELECT
    ROUND((FR.TotalFullReturns * 100.0 / TR.TotalReturns), 2) 
    AS FullReturnPercentage
FROM
    (SELECT COUNT(*) AS TotalFullReturns
     FROM Returns r
     INNER JOIN Sales s 
     ON r.OrderID = s.OrderID
     AND r.ReturnSales = s.Sales) AS FR,
    (SELECT COUNT(OrderID) AS TotalReturns
     FROM Returns) AS TR;
     
	
SELECT
    ROUND((FR.TotalFullReturns * 100.0 / TR.TotalReturns), 2) AS FullReturnPercentage
FROM
    (SELECT SUM(r.ReturnSales) AS TotalFullReturns
     FROM Returns r
     INNER JOIN Sales s 
     ON r.OrderID = s.OrderID
     AND r.ReturnSales = s.Sales) AS FR,
    (SELECT SUM(ReturnSales) AS TotalReturns
     FROM Returns) AS TR;



-- C) What is the average return % amount (return % of original sale)?

SELECT
    ROUND(AVG((r.ReturnSales / s.Sales) * 100), 2) AS AvgReturnPercentage
FROM Returns r
LEFT JOIN Sales s 
ON r.OrderID = s.OrderID;

-- D) What % of returns occur within 7 days of the original sale?	

SELECT 
ROUND((SUM(CASE WHEN DATEDIFF(r.ReturnDate, s.TransactionDate) <= 7 THEN 1 ELSE 0 END)/ COUNT(*)* 100.0 ),2) AS Percentage
FROM Returns r
JOIN Sales s 
ON r.OrderID = s.OrderID;


-- E) What is the average number of days for a return to occur?

SELECT 
ROUND(AVG(DATEDIFF(r.ReturnDate, s.TransactionDate))) AS AverageDaysToReturn
FROM Returns r
JOIN Sales s 
ON r.OrderID = s.OrderID;


-- F) Using this data set, how would you approach and answer the question, who is our most valuable customer?
WITH SalesData AS (
    SELECT CustomerID, ROUND(SUM(Sales),2) AS TotalSales, COUNT(OrderID) AS TotalOrders
    FROM Sales
    GROUP BY CustomerID
),
ReturnsData AS (
    SELECT CustomerID, ROUND(SUM(ReturnSales),2) AS TotalReturns
    FROM Returns
    GROUP BY CustomerID
),
CustomerMetrics AS (
    SELECT s.CustomerID, s.TotalSales,
        COALESCE(r.TotalReturns, 0) AS TotalReturns,
        ROUND((s.TotalSales - COALESCE(r.TotalReturns, 0)),2) AS NetSales,
        s.TotalOrders, ROUND((s.TotalSales / s.TotalOrders),2) AS AverageOrderValue
    FROM SalesData s
    LEFT JOIN ReturnsData r 
    ON s.CustomerID = r.CustomerID
)
SELECT CustomerID, TotalSales, TotalReturns, 
	   NetSales, TotalOrders, AverageOrderValue
FROM CustomerMetrics
ORDER BY 
    NetSales DESC, 
    AverageOrderValue DESC 
LIMIT 10;