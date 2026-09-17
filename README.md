# Azure Incremental Order Data Pipeline

## 📌 Overview

This project demonstrates an **incremental order data pipeline** using **GitHub REST API, Azure Data Factory, and SQL Server**.

Order data is stored as JSON in GitHub. Azure Data Factory retrieves the data and loads it into a SQL staging table. A stored procedure then performs an incremental upsert into the final `Orders` table.

## 🏢 Business Requirement

- Retrieve order data from GitHub using the REST API.
- Load the data into SQL Server through Azure Data Factory.
- Insert new orders.
- Update existing orders when newer data is available.
- Prevent duplicate `OrderID` records.
- Maintain the latest version of each order.

## 🏗️ Architecture

```text
             GitHub JSON
                    |
                    v
            GitHub REST API
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

## 🛠️ Technologies

- Azure Data Factory
- GitHub REST API
- SQL Server
- T-SQL
- JSON

## 🔄 Incremental Load Logic

The staging table may contain multiple versions of the same `OrderID`.

Example:

```text
OrderID | CustomerID | UpdatedDate
1002    | C002       | 2024-05-07
1002    | C003       | 2024-05-09
```

`ROW_NUMBER()` is used to keep the latest record based on `UpdatedDate`.

```sql
ROW_NUMBER() OVER (
    PARTITION BY OrderID
    ORDER BY UpdatedDate DESC
)
```

Then `MERGE` performs the upsert:

- **New OrderID → INSERT**
- **Existing OrderID + newer UpdatedDate → UPDATE**
- **Existing OrderID + no newer data → No change**

## 📂 Repository Structure

```text
incremental-project/
│
├── README.md
│
├── Data/
│   └── orders.json
│
├── SQL/
│   ├── create_tables.sql
|
└── screenshots/
    └── pipeline_success.png
```

## 🧠 Stored Procedure

The main procedure is:

```text
sp_upsert_orders
```

It:

1. Reads data from `temp_Orders`.
2. Keeps the latest record for each `OrderID`.
3. Compares the source with `dbo.Orders`.
4. Updates existing orders when the source is newer.
5. Inserts new orders.

## ✅ Result

The ADF pipeline successfully runs:

```text
Copy_Orders_To_Staging
        ↓
sp_upsert_orders
        ↓
dbo.Orders
```

The final table maintains the latest version of each `OrderID` without duplicate primary-key records.

## 🎯 Key Learning

- REST API data ingestion
- Azure Data Factory Copy Activity
- SQL staging tables
- Incremental loading
- Upsert logic
- Stored Procedures
- `MERGE`
- `ROW_NUMBER()`
- Data deduplication

Interested in **Azure Data Engineering, SQL, PySpark, and Cloud Data Platforms**.
