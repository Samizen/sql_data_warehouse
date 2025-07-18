/*
SQL Script: Database and Schema Initialization for DataWarehouse

Purpose: This script is designed to set up a new or refresh an existing
         'DataWarehouse' database, along with its core schemas.

Actions:
1. Connects to the 'master' database.
2. Checks if the 'DataWarehouse' database exists. If it does, it
   forces all active connections to terminate and then drops the database.
   This ensures a clean slate for database creation.
3. Creates a new 'DataWarehouse' database.
4. Switches the context to the newly created 'DataWarehouse' database.
5. Creates three essential schemas within 'DataWarehouse':
   - 'bronze': Typically used for raw, immutable data, ingested directly from source systems.
   - 'silver': Usually holds conformed, cleaned, and integrated data, often
               resulting from transformations applied to bronze data.
   - 'gold': Generally contains highly refined and aggregated data, optimized
             for reporting and analytical purposes.

Usage: Execute this script to prepare the 'DataWarehouse' environment
       for subsequent data loading and transformation processes.
*/



USE master;
GO

-- Drop and recreate the 'DataWarehouse' database if it already exists:
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
