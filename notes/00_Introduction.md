## Data Warehousing Tasks

&nbsp;       <img src="../_resources/95d2347a2ae465eef0f4ca3f2392de35.png" alt="95d2347a2ae465eef0f4ca3f2392de35.png" width="409" height="369" class="jop-noMdConv">

- Data Warehousing is foundation of any Data Analytics Project
- Data Warehouse is a subject-oriented, integrated, time-variant, and non-volatile collection of data in support of management's decision making process
    - Subject-oriented: DW is usually focused on a business-area like sales, customers, etc.
    - Integrated: It integrates multiple source systems.
    - Time-variant: You can keep historical data inside a data warehouse
    - Non-volatile: Once the data enters, it is usually not deleted or modified

&nbsp;

### Projects With Data Warehouses

&nbsp;               <img src="../_resources/40901cb346143fa882d54bfcf40a4915.png" alt="40901cb346143fa882d54bfcf40a4915.png" width="374" height="382" class="jop-noMdConv">

- Manual data collection is removed, ETL is responsible for it by extracting data from multiple sources, transforms the data to a usable state and then load the data into Data Warehouse
- Data Warehouse becomes single source of truth for analysis and reporting
    - All the reports will be using DW as the go to source
    - Integrated reports become possible
- Whole process is automated, which reduces human error and is very fast
- Historical data is preserved
- All reports will have same data status
- Big Data can be handled

&nbsp;

## What is ETL?

- Most part of the Data Warehouse project takes place in ETL

<img src="../_resources/54df2bb47fa0a3b473e0274c58e131e3.png" alt="54df2bb47fa0a3b473e0274c58e131e3.png" width="508" height="203" class="jop-noMdConv">

- The data exists in source system and the aim is to move it to the target (database tables)
- First step would be to identify which data to load from the source system, which is usually a subset of data from the source. This is the Extraction stage.
    - During Extraction, the data is not changed.
- Second step would be to take the extracted data and do some manipulation, transformations and change the data according to the requirement. This is the Transformation stage.
    - It includes Data Cleansing, Data Integration, formatting, normalization , etc.
- Finally, we will insert the transformed data into target.

![ETL.png](../_resources/ETL.png)

&nbsp;

&nbsp;