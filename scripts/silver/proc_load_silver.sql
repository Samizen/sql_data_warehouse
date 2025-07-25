GO
-- Inserting Data into Silver From Bronze after Data Transformation and Data Cleansing
CREATE OR ALTER PROCEDURE [silver].[load_silver] AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @start_silver_layer DATETIME, @end_silver_layer DATETIME
	BEGIN TRY
		PRINT '---------------------';
			PRINT 'Loading Silver Layer ';
			PRINT '---------------------';

			PRINT 'Loading Bronze CRM Tables...';

		SET @start_silver_layer = GETDATE()

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT 'Inserting Data Into: silver.crm_cust_info'
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
		SET @end_time = GETDATE()
		PRINT 'Time taken: ' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + 'ms'

		--- TABLE crm_prd_info
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		SET @start_time = GETDATE()
		PRINT 'Inserting Data Into: crm_prd_info'
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
		SET @end_time = GETDATE();
		PRINT 'Time taken: ' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + 'ms'

		-- crm_sales_details
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Truncating Table: silver.crm_sales_details';
		SET @start_time = GETDATE()
		PRINT '>> Inserting Data Into: silver.crm_sales_details'
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
		SET @end_time = GETDATE();
		PRINT 'Time taken: ' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + 'ms'


		-- Table silver.erp_cust_az12
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		PRINT 'Inserting Data Into: silver.erp_cust_az12'
		SET @start_time = GETDATE()
		INSERT INTO [silver].[erp_cust_az12] (
				   [cid]
				   ,[bdate]
				   ,[gen]
		)

		SELECT
				CASE WHEN [cid] LIKE 'NAS%' THEN SUBSTRING([cid], 4, LEN([cid]))
					 ELSE [cid]
					 END as [cid]
			  , CASE WHEN bdate > GETDATE() THEN NULL
				   ELSE bdate
				   END AS bdate
			  , CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
					 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
					 ELSE 'n/a'
					 END as [gen]
		  FROM [DataWarehouse].[bronze].[erp_cust_az12];
		SET @end_time = GETDATE();
		PRINT 'Time taken: ' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + 'ms'

		-- erp_loc_a101
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT 'Inserting Data Into: erp_loc_a101'
		SET @start_time = GETDATE()
		INSERT INTO silver.erp_loc_a101 (
					cid,
					cntry
		)
		SELECT
			REPLACE(cid, '-', '') as cid,
			CASE WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
				 WHEN UPPER(TRIM(cntry)) IN ('US', 'USA') THEN 'United States'
				 WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
				 ELSE TRIM(cntry) 
				 END AS cntry
		FROM bronze.erp_loc_a101;
		SET @end_time = GETDATE();
		PRINT 'Time taken: ' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + 'ms'

		-- table erp_px_cat_g1v2
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT 'Inserting Data Into: erp_px_cat_g1v2'
		SET @start_time = GETDATE()
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)

		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2
		SET @end_time = GETDATE();
		PRINT 'Time taken: ' + CAST(DATEDIFF(microsecond, @start_time, @end_time) AS NVARCHAR) + 'ms'
		SET @end_silver_layer = GETDATE()
		PRINT '--------------------------------------------';
		PRINT 'Time taken for Silver Layer: ' + CAST(DATEDIFF(microsecond, @start_silver_layer, @end_silver_layer) AS NVARCHAR) + 'ms'
		PRINT '--------------------------------------------';

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