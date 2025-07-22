&nbsp;       <img src="../_resources/76361b3eae181f8a09743ff2b7319805.png" alt="76361b3eae181f8a09743ff2b7319805.png" width="350" height="237" class="jop-noMdConv">

&nbsp;       <img src="../_resources/8a1c595a3773cb77fb8600056a570b27.png" alt="8a1c595a3773cb77fb8600056a570b27.png" width="524" height="111" class="jop-noMdConv">

### Data Profiling

- Explore the source data to identify the column names and data types

&nbsp;

### Creating tables for Bronze Schema

- Follow set naming conventions
- Column names will be identical to source system (view here[02_Design Data Architecture)](../Implementation%20of%20SQL%20Data%20Warehouse/02_Design%20Data%20Architecture.md)

&nbsp;

- Here is an example of turning cust_info.csv to a table in the database (create appropriate Database and Schema (bronze) in the database first):

```SQL
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
);
```

- remember to name the source crm_ for the table
- Table creation is done for each csv files
- remember to check the data types for accurate depiction of source data into these tables

&nbsp;

### Inserting Data into created tables:

- Bulk INSERT
    - Inserts data directly from csv file to the created table

```SQL
TRUNCATE TABLE bronze.crm_cust_info;
BULK INSERT bronze.crm_cust_info
FROM <the_file_location>
WITH (
    FIRSTROW = 2 -- Because the csv file contains the header row
    FIELDTERMINATOR = ','
);
```

&nbsp;

## Creating a Stored Procedures to run the data loading script

### Stored Procedures

- a precompiled set of SQL statements saved in the database that can be reused to perform tasks like inserting data, updating records, or running complex logic.
- They improve performance, security, and make code reusable.

```SQL
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @start_bronze_layer DATETIME, @end_bronze_layer DATETIME 
    /*These variables can be declared and used for checking how much time each table took to truncate and load and 
    the total time it took to load the batch */
    BEGIN TRY	
        PRINT '---------------------';
        PRINT 'Loading Bronze Layer ';
        PRINT '---------------------';
        PRINT 'Loading CRM Tables...';
        SET @start_bronze_layer = GETDATE()
        SET @start_time = GETDATE()
        PRINT '>> Truncating Table: bronze.crm_cust_info'; -- PRINT Statements log into console for debugging
    	
    	
    	... --(The Bulk Load Queries of each 6 tables)
    	
    	
    	END TRY
    BEGIN CATCH
    PRINT '--------------------------------------------';
    PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER...';
    PRINT '--------------------------------------------';
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Error No.' + CAST(ERROR_NUMBER() AS NVARCHAR);
    PRINT 'Error State.' + CAST(ERROR_STATE() AS NVARCHAR);
    END CATCH
END
```

- To Run this stored procedure:
    
- ```SQL
      EXEC bronze.crm_cust_info
    ```
    
- Also, include logging messages and TRY...CATCH statements to view the respective errors