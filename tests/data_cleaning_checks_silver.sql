-- Duplicate and NULL
SELECT
	cst_id,
	COUNT(*) AS Occurance -- COUNT(*) will also include NULL, instead of COUNT(cst_id)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL
ORDER BY Occurance DESC;

-- select * from silver.crm_cust_info WHERE cst_id IS NULL;
-- select * from silver.crm_cust_info WHERE cst_key IN ('SF566', 'PO25', '13451235');

-- Check for Unwanted Spaces
SELECT
	cst_firstname,
	cst_lastname,
	cst_gndr
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
	OR cst_lastname != TRIM(cst_lastname) 
	OR cst_gndr != TRIM(cst_gndr) 

-- Check for Data Standardization and Consistency
-- For Consistency in Low Cardinality columns
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;


---- Table crm_prd_info
SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	DATEADD(DAY, -1,LEAD(prd_start_dt, 1) OVER (PARTITION BY prd_key ORDER BY prd_end_dt)) AS prd_end_dt

FROM bronze.crm_prd_info;
-- WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')


SELECT DISTINCT prd_key
FROM (
	SELECT
		prd_id,
		prd_key,
		prd_nm,
		prd_start_dt,
		prd_end_dt,
		DATEADD(DAY, -1, LEAD(prd_start_dt, 1) OVER (PARTITION BY prd_key ORDER BY prd_end_dt)) AS adj_end_dt
	FROM bronze.crm_prd_info
	WHERE prd_start_dt > prd_end_dt
) AS sub;

-- crm_sales_detail
SELECT
	[sls_ord_num],
	[sls_prd_key],
	[sls_cust_id],
	[sls_order_dt],
	[sls_ship_dt],
	[sls_due_dt],
	[sls_sales],
	[sls_quantity],
	[sls_price]
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (
	SELECT prd_key 
	FROM silver.crm_prd_info
	WHERE prd_key IS NOT NULL
);

-- Date Check
SELECT 
	NULLIF(sls_order_dt, 0)
FROM bronze.crm_sales_details
WHERE sls_order_dt < = 0
	OR LEN(sls_order_dt) != 8
	OR sls_order_dt > 20500101
	OR sls_order_dt < 19000101


SELECT 
	NULLIF(sls_ship_dt, 0)
FROM bronze.crm_sales_details
WHERE sls_ship_dt < = 0
	OR LEN(sls_ship_dt) != 8
	OR sls_ship_dt > 20500101
	OR sls_ship_dt < 19000101;

SELECT 
	NULLIF(sls_due_dt, 0)
FROM bronze.crm_sales_details
WHERE sls_due_dt < = 0
	OR LEN(sls_due_dt) != 8
	OR sls_due_dt > 20500101
	OR sls_due_dt < 19000101

-- Order date should be smaller than shipping and due dates
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

SELECT *
FROM bronze.crm_sales_details
WHERE sls_ship_dt > sls_due_dt

-- Sales, Quantity and Price
SELECT 
	*
FROM bronze.crm_sales_details
WHERE sls_sales > sls_quantity * sls_price OR sls_sales IS NULL
	OR sls_price IS NULL OR sls_quantity IS NULL;
