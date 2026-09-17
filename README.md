# Incremental Order Data Load

## Overview

This project demonstrates an incremental data loading pipeline
using Azure Data Factory and SQL Server.

The pipeline loads order data into a staging table and then uses
a stored procedure to perform INSERT and UPDATE operations on the
target Orders table.

## Architecture

Source JSON
    ↓
Azure Data Factory
    ↓
temp_Orders (Staging)
    ↓
Stored Procedure
    ↓
Orders (Target)

## Technologies

- Azure Data Factory
- SQL Server
- T-SQL
- GitHub
- Incremental Data Loading

## Key Features

- Staging table for incoming data
- Incremental loading
- Duplicate OrderID handling
- Latest record selection using UpdatedDate
- MERGE-based upsert
- INSERT for new orders
- UPDATE for existing orders

## Stored Procedure

The stored procedure `sp_upsert_orders` compares staging data
with the target Orders table.

If the OrderID already exists and the incoming UpdatedDate is newer,
the existing record is updated.

If the OrderID does not exist, a new record is inserted.

## Pipeline

The Azure Data Factory pipeline contains:

1. Copy_Orders_To_Staging
2. sp_upsert_orders

Both activities successfully execute the incremental load.
