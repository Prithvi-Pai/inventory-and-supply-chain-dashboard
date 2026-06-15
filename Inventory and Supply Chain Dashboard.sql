create database 048_inventory_supply_chain_db;
use 048_inventory_supply_chain_db ;
SET GLOBAL local_infile = 1;

select * From fulfillment;
select * from inventory;
select * from orders_and_shipments;

SELECT
    o.*,
    i.`Product Name`,
    i.`Year Month`,
    i.`Warehouse Inventory`,
    i.`Inventory Cost Per Unit`,
    f.`Warehouse Order Fulfillment (days)`
FROM orders_and_shipments o
LEFT JOIN inventory i
    ON o.`Product ID` = i.`Product ID`
LEFT JOIN fulfillment f
    ON o.`Product ID` = f.`Product ID`;
    
-- Inventory Cost & Warehouse inventory
SELECT
        SUM(`Inventory Cost Per Unit`) AS inventory_cost_per_unit,
        sum(`Warehouse Inventory`) AS warehouse_inventory
    FROM inventory;
--  Average fulfillment Days
SELECT
        AVG(`Warehouse Order Fulfillment (days)`) AS fulfillment_days
    FROM fulfillment;
--  Storage Cost
SELECT
    SUM(`Inventory Cost Per Unit` * `Warehouse Inventory`) AS Storage_Cost
FROM inventory ;
-- Total order quantity by Department
SELECT
    `Product Department`,
    SUM(`Order Quantity`) AS Total_Order_Quantity
FROM orders_and_shipments
GROUP BY `Product Department`
ORDER BY Total_Order_Quantity DESC;
-- Storage Cost by Department (using subquery)
SELECT
    d.`Product Department`,
    SUM(i.`Inventory Cost Per Unit` * i.`Warehouse Inventory`) AS Storage_Cost
FROM inventory i
JOIN (
    SELECT DISTINCT
        `Product ID`,
        `Product Department`
    FROM orders_and_shipments
) d
ON i.`Product ID` = d.`Product ID`
GROUP BY d.`Product Department`
ORDER BY Storage_Cost DESC;
-- Find products with fulfillment days more than 5
SELECT *
FROM fulfillment
WHERE `Warehouse Order Fulfillment (days)` > 5;
-- Find departments with total order quantity greater than 5000
SELECT
    `Product Department`,
    SUM(`Order Quantity`) AS Total_Order_Quantity
FROM orders_and_shipments
GROUP BY `Product Department`
HAVING SUM(`Order Quantity`) > 5000
ORDER BY Total_Order_Quantity DESC;
-- Rank products based on Warehouse Inventory.
SELECT
    `Product ID`,
    `Product Name`,
    `Warehouse Inventory`,
    RANK() OVER (
        ORDER BY `Warehouse Inventory` DESC
    ) AS Inventory_Rank
FROM inventory;
-- Dense rank products based on Inventory Cost Per Unit.
SELECT
    `Product ID`,
    `Product Name`,
    `Inventory Cost Per Unit`,
    DENSE_RANK() OVER (
        ORDER BY `Inventory Cost Per Unit` DESC
    ) AS Cost_Rank
FROM inventory;
-- Assign row numbers to orders within each department
SELECT
    `Product Department`,
    `Product ID`,
    `Order Quantity`,
    ROW_NUMBER() OVER (
        PARTITION BY `Product Department`
        ORDER BY `Order Quantity` DESC
    ) AS Row_Num
FROM orders_and_shipments;
-- Calculate cumulative order quantity by department (yoy KPI)
SELECT
    `Product Department`,
    `Order Year`,
    Total_Order_Quantity,
    SUM(Total_Order_Quantity) OVER (
        PARTITION BY `Product Department`
        ORDER BY `Order Year`
    ) AS Running_Total
FROM
(
    SELECT
        `Product Department`,
        `Order Year`,
        SUM(`Order Quantity`) AS Total_Order_Quantity
    FROM orders_and_shipments
    GROUP BY
        `Product Department`,
        `Order Year`
) t;

-- Top 3 departments by total order quantity.
SELECT *
FROM
(
    SELECT
        `Product Department`,
        SUM(`Order Quantity`) AS Total_Order_Quantity,
        RANK() OVER (
            ORDER BY SUM(`Order Quantity`) DESC
        ) AS Dept_Rank
    FROM orders_and_shipments
    GROUP BY `Product Department`
) x
WHERE Dept_Rank <= 3;