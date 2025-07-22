- The data transformation happens in this layer.
- To glimpse into the future and how the transformation should aid the Data Integration between different tables, create an integration diagram.

&nbsp;       <img src="../_resources/ac600ea30625ea71e726815ac2549184.png" alt="ac600ea30625ea71e726815ac2549184.png" width="308" height="214" class="jop-noMdConv">

&nbsp;       <img src="../_resources/c93561b088d2f245034fee990e8d0c2c.png" alt="c93561b088d2f245034fee990e8d0c2c.png" width="441" height="167" class="jop-noMdConv">

## Data Integration Model

&nbsp;       <img src="../_resources/ca3b7bdd06ba7ee5b7dd65b6ae47663b.png" alt="ca3b7bdd06ba7ee5b7dd65b6ae47663b.png" width="576" height="281" class="jop-noMdConv">

### Creating Tables for Silver Schema

- Again, here is an example of creation of silver.crm_cust_info

```SQL
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE(), -- table identical to bronze except this column
);
```

- A metadata column of date and time of insertion is added so that it can be used for debugging and extra information

## Cleaning and Loading Tables

## 1\. <ins>crm_cust_info</ins>

- Here is a view of bronze.crm_cust_info

&nbsp;       ![be0fa317247d6939434fa712861eebe4.png](../_resources/be0fa317247d6939434fa712861eebe4.png)

- Go column by column for data cleaning and checking

### PK NULL or repeated

```SQL
-- Duplicate and NULL
SELECT
    cst_id,
    COUNT(*) AS Occurance -- COUNT(*) will also include NULL, instead of COUNT(cst_id)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL
ORDER BY Occurance DESC;
```

&nbsp;       ![213fe26bcd5a984c8709ca1fd8941d01.png](../_resources/213fe26bcd5a984c8709ca1fd8941d01.png)

- As seen above, there are instances of repeated PKs in the data.

**Query to handle this**

```SQL
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info
```

&nbsp;       ![6b70fa626088f30c5a44b402f337104f.png](../_resources/6b70fa626088f30c5a44b402f337104f.png)

- The last flag will be used for the repeated cst_id for e.g cst_id 29566 has repeated for 3 times but flag_last = 3 will be used
    - Check for all data with discrepencies  
        \- Same NULL and duplicate check was done for cst_key which know will be used to JOIN with another table from the Data Integration Model above

### Texts with unwanted spaces

- For columns containing texts, check for unwanted spaces

```SQL
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
```

- If found, use TRIM(cst_firstname) to transform the column in our final query.

### Data Normalization (For low cardinality columns)

- To maintain a consistent data in fields used for classification - for e.g. cst_marital_status (S, M) and cst_gndr (M, F), data normalization and standardization is done.
- First check for the unique values in the column to check for any discrepencies

```SQL
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info
```

&nbsp;        ![22eea6952de8804238f315efa84c6fe9.png](../_resources/22eea6952de8804238f315efa84c6fe9.png)

- A mapping is done with proper value for M = Male, F = Female and NULL = n/a

**Query to handle this:**

```SQL
...,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
     WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
     ELSE 'n/a'
     END AS cst_gndr,
...
```

- Also check date if there is error in formatting

&nbsp;

### Final Transformed Query and Its Insertion into silver.crm_cust_info table

```SQL
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)

SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
         WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
         ELSE 'n/a' 
    END AS cst_marital_status,
    CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
         WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
         ELSE 'n/a' 
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
) t
WHERE flag_last = 1 AND cst_id IS NOT NULL
```

&nbsp;

## 2\. <ins>crm_prd_info</ins>

![882fe48423a77b13a3721d8699ff6208.png](../_resources/882fe48423a77b13a3721d8699ff6208.png)

- Check for PK NULL and/or duplicate like above
- Check for unwanted spaces in texts like above
- Check for low cardinality columns for classification like prd_line using CASE statement like before

&nbsp;

### Derived Columns (creating new columns from the ones in the table)

- Since the integration diagram (at the top) shows that product_key is required to JOIN with another table, check if the join is possible or not with current data
- The other table has following key for the join which is a part of prd_key

&nbsp;       ![0395ddd461a7430b2410e9047a43e832.png](../_resources/0395ddd461a7430b2410e9047a43e832.png)

- Two problems needs to be addressed:
    - The first 5 characters has to be taken out from the prd_key in crm_prod_info
    - The dash (-) has to be replaced by underscore like it is in the other table for the JOIN to be possible

Query to address this:

```SQL
...,
,REPLACE(SUBSTRING([prd_key], 1, 5), '-', '_') AS [cat_id]
,REPLACE(SUBSTRING([prd_key], 7, LEN([prd_key])), '-', '_') AS [prd_key], -- also store the prd_key to keep the information
...
```

### Handling the integers

- Check if the values like cost are NULL or negative. If NULL change it to 0, and if -ve, change it with consultation from SME
    - COALESCE(prd_cost, 0)

&nbsp;

### Handling start_date and end_date logic

- the value with end_date = NULL is the current price for the product according to the business logic (only in this case)
- start_date should always be before end_date
    - We'll handle this by setting the end_date as start date of the product and subtract a day to it

&nbsp;               <img src="../_resources/24481d3303f7189e07c0f6f06a9239cd.png" alt="24481d3303f7189e07c0f6f06a9239cd.png" width="342" height="132" class="jop-noMdConv">

**Query to handle this**

```SQL
...,
DATEADD(DAY, -1,LEAD(prd_start_dt, 1) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt,
...
```

### Final Transformed Query and Its Insertion into silver.crm_cust_info table

```SQL
INSERT INTO  [silver].[crm_prd_info](
    [prd_id],
    [cat_id],
    [prd_key],
    [prd_nm],
    [prd_cost],
    [prd_line],
    [prd_start_dt],
    [prd_end_dt]
) 

SELECT
       [prd_id]
      ,REPLACE(SUBSTRING([prd_key], 1, 5), '-', '_') AS [cat_id]
      ,REPLACE(SUBSTRING([prd_key], 7, LEN([prd_key])), '-', '_') AS [prd_key]
      ,[prd_nm]
      ,COALESCE(prd_cost, 0) AS prd_cost
      ,CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mounting'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line
      ,CAST([prd_start_dt] AS DATE) AS [prd_start_date]
      ,DATEADD(DAY, -1,LEAD(prd_start_dt, 1) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt  
FROM [DataWarehouse].[bronze].[crm_prd_info];
```

&nbsp;

## 3\. <ins>crm_sales_details</ins>

&nbsp;       ![fb0262e62703516983d89bd646a88681.png](../_resources/fb0262e62703516983d89bd646a88681.png)

- Check for NULL and repeated PK like before

### Converting the Date columns

- Check if the date is less than 0 or 0
    - Convert them to NULL if that is the case: NULLIF(sls_order_date, 0)
- Check if the date is ready for standard format - i.e. length of 8: LEN(sls_order_date) != 8 - 20110105
    - Query to handle this:
    - ```SQL
        CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
             ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
             END AS [sls_order_dt]
        ```
        
    - Do the same for all date columns
- Check if Order Date > Shipping Date > Due Date

### Checking Derived Values

- For the values that depend on one another: sls_sales = sls_quantity \* sls_price, where -ve, 0 and NULLs should not be possible
- ```SQL
    ...,
    COALESCE([sls_sales], [sls_price]/[sls_quantity]) AS [sls_sales],
    COALESCE([sls_quantity],[sls_sales]/[sls_price]) AS [sls_quantity],
    CASE WHEN [sls_price] < 0 THEN [sls_sales]*[sls_quantity]
        ELSE COALESCE([sls_price], [sls_sales]/[sls_quantity])
        END AS [sls_price],
    ...
    ```
    

### Final Transformed Query and Its Insertion into silver.crm_cust_info table

```SQL
INSERT INTO [silver].[crm_sales_details] (
            [sls_ord_num]
           ,[sls_prd_key]
           ,[sls_cust_id]
           ,[sls_order_dt]
           ,[sls_ship_dt]
           ,[sls_due_dt]
           ,[sls_sales]
           ,[sls_quantity]
           ,[sls_price]
)
SELECT
    [sls_ord_num],
    [sls_prd_key],
    [sls_cust_id],
    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
         ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
         END AS [sls_order_dt],
    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
         ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
         END AS [sls_ship_dt],
    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
     ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
     END AS [sls_due_dt],
    COALESCE([sls_sales], [sls_price]/[sls_quantity]) AS [sls_sales],
    COALESCE([sls_quantity],[sls_sales]/[sls_price]) AS [sls_quantity],
    CASE WHEN [sls_price] < 0 THEN [sls_sales]*[sls_quantity]
        ELSE COALESCE([sls_price], [sls_sales]/[sls_quantity])
        END AS [sls_price]
FROM bronze.crm_sales_details;
```

&nbsp;

## 4\. erp_cust_az12, 5. erp_loc_a101, 6. erp_px_cat_g1v2

- same process as above for all remaining tables
- Check for NULL and duplicate PKs
- Check for date format, if multiple dates are present, check if one should be greater or smaller than other or any designated values
- Data normalization and Standardization for low cardinality columns for classification
- Finally, put all the insertion code into one and create a stored procedure load_silver like done before for load_bronze

&nbsp;

&nbsp;