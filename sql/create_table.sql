CREATE TABLE dbo.Orders(
    OrderID INT PRIMARY KEY,
    CustomerID NVARCHAR(50),
    OrderDate DATETIME,
    UpdatedDate DATETIME,
    Amount FLOAT
);

CREATE TABLE dbo.temp_orders(
    OrderID INT,
    CustomerID NVARCHAR(50),
    OrderDate DATETIME,
    UpdatedDate DATETIME,
    Amount FLOAT
);

CREATE OR ALTER PROCEDURE dbo.sp_upsert_orders
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH LatestOrders AS
    (
        SELECT
            OrderID,
            CustomerID,
            OrderDate,
            UpdatedDate,
            Amount,
            ROW_NUMBER() OVER (
                PARTITION BY OrderID
                ORDER BY UpdatedDate DESC
            ) AS rn
        FROM dbo.temp_Orders
    )

    MERGE dbo.Orders AS Target
    USING
    (
        SELECT
            OrderID,
            CustomerID,
            OrderDate,
            UpdatedDate,
            Amount
        FROM LatestOrders
        WHERE rn = 1
    ) AS Source

    ON Target.OrderID = Source.OrderID

    -- Existing order: update only if source is newer
    WHEN MATCHED
         AND Source.UpdatedDate > Target.UpdatedDate
    THEN
        UPDATE SET
            Target.CustomerID = Source.CustomerID,
            Target.OrderDate = Source.OrderDate,
            Target.UpdatedDate = Source.UpdatedDate,
            Target.Amount = Source.Amount

    -- New order: insert
    WHEN NOT MATCHED BY TARGET
    THEN
        INSERT
        (
            OrderID,
            CustomerID,
            OrderDate,
            UpdatedDate,
            Amount
        )
        VALUES
        (
            Source.OrderID,
            Source.CustomerID,
            Source.OrderDate,
            Source.UpdatedDate,
            Source.Amount
        );

END;

SELECT * FROM orders;

SELECT * FROM temp_orders;

--  stored procedure does three things:

-- 1. Remove duplicate versions → Keep latest record
-- 2. Existing OrderID → Update if the new record is newer
-- 3. New OrderID → Insert it

-- That's the core of your incremental upsert.
