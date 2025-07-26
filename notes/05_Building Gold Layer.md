&nbsp;       <img src="../_resources/e2242b91bf846c9618a6e0bd029b1fb6.png" alt="e2242b91bf846c9618a6e0bd029b1fb6.png" width="459" height="272" class="jop-noMdConv">

&nbsp;               <img src="../_resources/11922d1e0a27e6fb3bb01f052722b67f.png" alt="11922d1e0a27e6fb3bb01f052722b67f.png" width="455" height="150" class="jop-noMdConv">

&nbsp;

## Types of Schemas

- For Analytics, Data Warehousing and BI, we need data model optimized for analytics and reporting.
    - It should be flexible, scalable, and easy to understand

### Star Schema

&nbsp;       ![](https://www.softwareag.com/content/dam/softwareag/global/image/blog/streamsets/2023/schemas-used-in-data-warehouses/star-schema.svg)<img src="../_resources/bea82e43a0bd37d5d956fc34cc79b5ff.png" alt="bea82e43a0bd37d5d956fc34cc79b5ff.png" width="372" height="208" class="jop-noMdConv">![](https://www.softwareag.com/content/dam/softwareag/global/image/blog/streamsets/2023/schemas-used-in-data-warehouses/star-schema.svg)![](https://www.softwareag.com/content/dam/softwareag/global/image/blog/streamsets/2023/schemas-used-in-data-warehouses/star-schema.svg)![](https://www.softwareag.com/content/dam/softwareag/global/image/blog/streamsets/2023/schemas-used-in-data-warehouses/star-schema.svg)

- It has a central fact table, which is surrounded by Dimensional tables like the image above.
- Fact table contains transactions, events
    - contains quantitative information that represents events
    - answers questions like How Much? How Many?
    - e.g. sales amount, order quantity, revenue, etc.
- Dimension table contains descriptive information
    - contains descriptive information that give context to your data
        - for e.g. customer names, product categories, dates, locations, etc.
    - answers questions like Who? What? Where?

### Snowflake Schema

&nbsp;       <img src="../_resources/bc1af0b125c7cf5af13ab9e4d3504b5d.png" alt="bc1af0b125c7cf5af13ab9e4d3504b5d.png" width="602" height="317" class="jop-noMdConv">

- Also contains a central Fact table and is surrounded by Dimension tables
- But, the Dimension tables are further divided into subdimensions

&nbsp;

## Exploring Business Objects

&nbsp;       <img src="../_resources/ca3b7bdd06ba7ee5b7dd65b6ae47663b.png" alt="ca3b7bdd06ba7ee5b7dd65b6ae47663b.png" width="576" height="281" class="jop-noMdConv">

### Customer Dimension table

- The aim is to create a table that joins crm_cust_info with erp_cust_az12 and erp_loc_a101, which are the three customer tables involved in our database.

```SQL
SELECT 
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    cl.cntry AS country,
    ci.cst_marital_status AS marital_status,
    ci.cst_gndr, -- gender column
    ca.gen,  -- another gender column
    ca.bdate AS birth_date,
    ci.cst_create_date AS created_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
    ON ci.cst_key = cl.cid
```

## Data Integration

- There are two gender columns from different tables in our join and this needs to be sorted

&nbsp;       ![e3b198e91b944b81025393573ad2ad91.png](../_resources/e3b198e91b944b81025393573ad2ad91.png)

- Check the data match from two

```SQL
SELECT DISTINCT
    ci.cst_gndr,
    ca.gen
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
ON ci.cst_key = cl.cid
ORDER BY 1, 2;
```

&nbsp;       ![f8f63b7c3c57afeaf1c546f4726c98e3.png](../_resources/f8f63b7c3c57afeaf1c546f4726c98e3.png)

- So, there are discrepencies between the columns
- To handle this, ask the SMEs on which source system should be treated as primary.
    - For now, handle this so that CRM is the main source, and assign values of CRM to the final table
        
        - If the CRM gender (ci.cst_gndr) is not 'n/a' → Use the CRM gender (ci.cst_gndr)
            
        - Else (i.e., it's 'n/a' or missing) → Try to use the ERP gender (ca.gen) → If that's also NULL, default to 'n/a'
            
    - ```SQL
              ...,
              CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
                   ELSE COALESCE(ca.gen, 'n/a')
                   END AS new_gender,
              ...
        ```
        

&nbsp;

- Rename all the columns to an understandable names and order it well according to important groups
- Classify this table as Fact or Dimension - of course this is about the customers with no transaction data so is **Dimension**

&nbsp;

### Create View

```SQL
SELECT 
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- add surrogate key to join with Fact tables
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    cl.cntry AS country,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'n/a' THEN cst_gndr
         ELSE COALESCE(ca.gen, 'n/a')
         END AS gender,
    ca.bdate AS birth_date,
    ci.cst_create_date AS created_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
    ON ci.cst_key = cl.cid
```

&nbsp;

## Create Dimension Product (historical)

- Follow the same process as above to JOIN the related tables
- The only decision that needs to be made is whether to keep historical records or not. Here according to the requirement, it is not necessary to do so.
- Dimension or Fact?
    - information about products, not transactional data - So, Dimension

```SQL
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pi.prd_start_dt, pi.prd_key) AS product_key,
    pi.prd_id AS product_id,
    pi.prd_key AS product_number,
    pi.prd_nm AS product_name,
    pi.cat_id AS catergory_id, 
    ep.cat AS category,
    ep.subcat AS subcategory,
    ep.maintenance,
    pi.prd_cost AS product_cost,
    pi.prd_line AS product_line,
    pi.prd_start_dt AS start_date
FROM silver.crm_prd_info pi
LEFT JOIN silver.erp_px_cat_g1v2 ep
    ON pi.cat_id = ep.id
WHERE pi.prd_end_dt IS NULL;
```

&nbsp;

## Create Fact Sales

- For fact_sales, remove the
- Fact table because it contains transaction, even, measures that connect to multiple dimension.
- Remove the sls_prd_key and sls_cust_id from silver layer and replace it with surrogate keys of the dimension tables to allow joining of Fact and Dimensions table

&nbsp;       ![648f4312a023969172cca1b50bd0d5c8.png](../_resources/648f4312a023969172cca1b50bd0d5c8.png)

```SQL
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales,
    sd.sls_quantity AS quantiry,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
-- JOIN with dimension tables
LEFT JOIN gold.dim_products dp
    ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc
    ON sd.sls_cust_id = dc.customer_id
```

&nbsp;       ![225441f4f5fe189cb188e3f42b07618e.png](../_resources/225441f4f5fe189cb188e3f42b07618e.png)

### Final Data Model

&nbsp;       <img src="../_resources/912a0fa9fc7e9d9dd72dfb912c9db82c.png" alt="912a0fa9fc7e9d9dd72dfb912c9db82c.png" width="695" height="251">

&nbsp;

### Final Data Flow Diagram

&nbsp;       <img src="../_resources/cca7d5845c9d5d25ee4e9b0dd91ed492.png" alt="cca7d5845c9d5d25ee4e9b0dd91ed492.png" width="673" height="339" class="jop-noMdConv">