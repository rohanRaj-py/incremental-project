# Azure Incremental Order Data Pipeline

## 📌 Project Overview

This project demonstrates an **incremental order data pipeline** built
using **Azure Data Factory and SQL Server**.

The project is based on a retail business requirement where order data
is received from an API in **JSON format**. The goal is to load the data
into a dedicated SQL `Orders` table while avoiding duplicate records and
updating existing orders when newer information is available.

------------------------------------------------------------------------

## 🏢 Business Requirement

A retail client wants:

-   A dedicated SQL table containing complete order information.
-   Order data coming from an API in JSON format.
-   Data to be ingested using Azure Data Factory.
-   New order records to be inserted into the SQL table.
-   Existing orders to be updated when new information is received.
-   Only incremental/latest data to be maintained in the final `Orders`
    table.
-   Duplicate `OrderID` records should not be created.

------------------------------------------------------------------------

## 🏗️ Project Architecture

``` text
             API / JSON Data
                    |
                    v
          Azure Data Factory
                    |
                    v
           temp_Orders
          (Staging Table)
                    |
                    v
          sp_upsert_orders
                    |
          +---------+---------+
          |                   |
       New Order        Existing Order
          |                   |
       INSERT       UpdatedDate is newer?
                              |
                         +----+----+
                         |         |
                        YES        NO
                         |         |
                      UPDATE     Ignore
                         |
                         v
                    dbo.Orders
```

------------------------------------------------------------------------

## 🛠️ Technologies Used

-   **Azure Data Factory** -- Pipeline orchestration and data ingestion
-   **SQL Server** -- Staging and target database
-   **T-SQL** -- Stored procedure and data processing
-   **JSON** -- Source data format
-   **GitHub** -- Source code and project documentation

------------------------------------------------------------------------

## 🔄 Pipeline Flow

The Azure Data Factory pipeline contains two main activities:

### 1. Copy_Orders_To_Staging

The Copy Data activity reads the order data from the JSON source and
loads it into the SQL staging table:

``` text
temp_Orders
```

The staging table temporarily stores the incoming data before it is
processed.

### 2. sp_upsert_orders

After the staging load succeeds, the stored procedure processes the data
and loads the correct records into:

``` text
dbo.Orders
```

The stored procedure uses `ROW_NUMBER()` and `MERGE` to handle
incremental loading.

------------------------------------------------------------------------

## 🔁 Incremental Load Logic

The project handles three main scenarios.

### Scenario 1: New Order

If an `OrderID` does not exist in the target table:

``` text
Source OrderID → Not found in Orders
                    ↓
                  INSERT
```

Example:

``` text
OrderID = 1008
```

If `1008` does not exist in `dbo.Orders`, it is inserted.

------------------------------------------------------------------------

### Scenario 2: Existing Order With an Update

If the `OrderID` already exists, the `UpdatedDate` is compared.

``` text
Source UpdatedDate > Target UpdatedDate
                ↓
              UPDATE
```

Example:

``` text
Existing:
1002 | C002 | 2024-05-07

New:
1002 | C003 | 2024-05-09
```

The newer record is selected and the target record is updated:

``` text
1002 | C003 | 2024-05-09
```

This prevents a duplicate `OrderID`.

------------------------------------------------------------------------

### Scenario 3: Duplicate Order Versions in Staging

Sometimes the staging table can contain multiple records for the same
`OrderID`.

Example:

``` text
OrderID | CustomerID | UpdatedDate
1002    | C002       | 2024-05-07
1002    | C003       | 2024-05-09
```

The project uses `ROW_NUMBER()`:

``` sql
ROW_NUMBER() OVER (
    PARTITION BY OrderID
    ORDER BY UpdatedDate DESC
)
```

This assigns the newest record `rn = 1`.

Only the latest version is processed:

``` sql
WHERE rn = 1
```

Therefore:

``` text
1002 | C003 | 2024-05-09
```

is retained instead of inserting multiple versions into the final table.

------------------------------------------------------------------------

## 🗄️ Database Tables

### Staging Table

``` text
dbo.temp_Orders
```

This table receives the incoming data from Azure Data Factory.

Example columns:

  Column        Description
  ------------- -------------------------
  OrderID       Unique order identifier
  CustomerID    Customer identifier
  OrderDate     Date of the order
  UpdatedDate   Last update timestamp
  Amount        Order amount

### Target Table

``` text
dbo.Orders
```

This table stores the latest/current version of each order.

`OrderID` is used as the primary key.

------------------------------------------------------------------------

## 🧠 Stored Procedure Logic

The stored procedure:

``` text
sp_upsert_orders
```

performs the following steps:

1.  Reads data from `temp_Orders`.
2.  Identifies duplicate `OrderID` values.
3.  Keeps the latest record based on `UpdatedDate`.
4.  Compares the staging data with `dbo.Orders`.
5.  Updates an existing order if the incoming record is newer.
6.  Inserts the order if it does not already exist.

The main SQL concepts used are:

-   `ROW_NUMBER()`
-   `PARTITION BY`
-   `ORDER BY`
-   `MERGE`
-   `INSERT`
-   `UPDATE`
-   Primary key validation

------------------------------------------------------------------------

## 📂 Repository Structure

``` text
incremental-project/
│
├── README.md
│
├── Data/
│   └── orders.json
│
├── SQL/
│   ├── create_tables.sql
│   └── sp_upsert_orders.sql
│
└── ADF/
    └── screenshots/
        └── pipeline_success.png
```

------------------------------------------------------------------------

## ✅ Pipeline Result

The pipeline successfully executes:

``` text
Copy_Orders_To_Staging
        ↓
     Succeeded
        ↓
sp_upsert_orders
        ↓
     Succeeded
```

The final `Orders` table contains the latest version of each `OrderID`
without creating duplicate primary-key records.

------------------------------------------------------------------------

## 🎯 Key Learning

Through this project, I learned how to implement an incremental data
loading process using Azure Data Factory and SQL Server.

The main concepts I practiced were:

-   Azure Data Factory pipelines
-   Copy Activity
-   SQL staging tables
-   Incremental loading
-   Upsert logic
-   Stored procedures
-   `MERGE`
-   Data deduplication
-   `ROW_NUMBER()`
-   Handling updated records
-   Primary key constraints

------------------------------------------------------------------------

## 🚀 Future Improvements

Possible improvements to this project include:

-   Connecting directly to a live REST API instead of sample JSON.
-   Adding ADF triggers for scheduled execution.
-   Adding logging and error-handling activities.
-   Adding audit columns such as load timestamp.
-   Adding a watermark-based incremental load.
-   Extending the pipeline to customers and products.

------------------------------------------------------------------------

## 👨‍💻 Author

**Rohan Raj**

B.Tech -- Computer Science & Engineering (Data Science)

Interested in **Azure Data Engineering, Data Engineering, SQL, PySpark,
and Cloud Data Platforms**.
