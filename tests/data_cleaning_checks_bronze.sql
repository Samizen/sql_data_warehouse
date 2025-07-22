-- Duplicate and NULL
SELECT
	cst_id,
	COUNT(*) AS Occurance -- COUNT(*) will also include NULL, instead of COUNT(cst_id)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL
ORDER BY Occurance DESC;

-- select * from bronze.crm_cust_info WHERE cst_id IS NULL;
-- select * from bronze.crm_cust_info WHERE cst_key IN ('SF566', 'PO25', '13451235');

-- Check for Unwanted Spaces
SELECT
	cst_firstname,
	cst_lastname,
	cst_gndr
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
	OR cst_lastname != TRIM(cst_lastname) 
	OR cst_gndr != TRIM(cst_gndr) 

-- Check for Data Standardization and Consistency
-- For Consistency in Low Cardinality columns
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;


-- erp_cust_az12
SELECT
	cid,
	COUNT(*) AS Occurance -- COUNT(*) will also include NULL, instead of COUNT(cst_id)
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL
ORDER BY Occurance DESC;

SELECT bdate
FROM bronze.erp_cust_az12; 

SELECT * from bronze.crm_cust_info;


-- erp_loc_a101
SELECT
	cid,
	COUNT(*) AS Occurance -- COUNT(*) will also include NULL, instead of COUNT(cst_id)
FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1 OR cid IS NULL
ORDER BY Occurance DESC;