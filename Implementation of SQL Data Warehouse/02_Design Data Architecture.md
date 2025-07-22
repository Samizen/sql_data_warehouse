## Choose the Right Approach

&nbsp;       <img src="../_resources/4e4ea2cf8b31430964577a0610f6a03f.png" alt="4e4ea2cf8b31430964577a0610f6a03f.png" width="525" height="147" class="jop-noMdConv">

**Data Warehouse**

- suitable for structured data
- if business wants to create a solid foundation on reporting and BI

&nbsp;

**Data Lake**

- is way more flexible than Data Warehouse
- can be used for structured, semi-structured, and unstructured data
- if business want to focus on Advanced Analytics, Machine Learning
- not as organized as Data Warehouse

&nbsp;

**Data Lakehouse**

- mix between Data Warehouse and Data Lake
- flexibility of having different types of data - structured, semi-structured, and unstructured
- but still want to organize data like we do in Data Warehouse

&nbsp;

**Data Mesh**

- instead of a centralized Data Management System, the idea is to make it decentralized.

&nbsp;

## Approaches for building Data Warehouse

**Inmon**

&nbsp;       <img src="../_resources/ca5dc403f194977b545d813f36a3f80e.png" alt="ca5dc403f194977b545d813f36a3f80e.png" width="190" height="351" class="jop-noMdConv">

- Starts with staging
- Organization of data happens in Enterprise Data Warehouse
- A small subset of Data Warehouse (Data Marts) is taken and designed to be consumed by Reporting that focuses only on one topic.
- All the tables in the Enterprise Data Warehouse are in 3rd Normal Form
- Emphasizes on enterprise-wide consistency

&nbsp;

**Kimball**

- This approach removes the building of Enterprise Data Warehouse, as it takes a lot of time, so it jumps directly from Staging to Data Marts.
- Some transformations might be repeated in multiple Data Marts
- Focuses on business-process-specific solutions
- Introduced now popular Star Schema for Data Marts

&nbsp;

Medallion

<img src="../_resources/7b14eeb2807f8f0b23b89fc726e5a5e9.png" alt="7b14eeb2807f8f0b23b89fc726e5a5e9.png" width="600" height="224" class="jop-noMdConv">

- It is a modern multi-layered architecture - mainly used in Data Lakehouse. It consists of three layers:
    - Bronze Layer
        - ingests raw, unprocessed data from source system similar to Staging in earlier architecture
        - raw data stored as-is for traceability
    - Silver Layer
        - cleaned, transformed and joined data
        - removal of duplicates, standardization of formats, joining of tables happens in this layer
    - Gold Layer
        - Aggregated, business level data - optimized for dashboards and KPI
        - not only for reporting, but also for models for AI/ML

&nbsp;

The choices made in this project: **Medallion Architecture**

&nbsp;               <img src="../_resources/8301b950189d9faa97d036563c4e6bd1.png" alt="8301b950189d9faa97d036563c4e6bd1.png" width="789" height="428" class="jop-noMdConv">

&nbsp;

## Data Architecture

<img src="../_resources/data_architecture.png" alt="data_architecture.png" width="822" height="486" class="jop-noMdConv">

## Files and snippets of each files:

- Source Files
    - CRM
        - cust_info

&nbsp;               <img src="../_resources/99d53dca511b0a786c20c3be81ded175.png" alt="99d53dca511b0a786c20c3be81ded175.png" width="488" height="249" class="jop-noMdConv">

- - - prd_info

&nbsp;               <img src="../_resources/17cbff234721bae5ed224afdf9125074.png" alt="17cbff234721bae5ed224afdf9125074.png" width="493" height="239" class="jop-noMdConv">

- - - sales_details

&nbsp;               <img src="../_resources/9f9b42f85b4226518de70e9ffaa5dc22.png" alt="9f9b42f85b4226518de70e9ffaa5dc22.png" width="558" height="217" class="jop-noMdConv">

- - ERP  
        \- CUST_AZ12

&nbsp;               <img src="../_resources/f2f7c55dff45cc3194b1c7a6150191d4.png" alt="f2f7c55dff45cc3194b1c7a6150191d4.png" width="192" height="141" class="jop-noMdConv">

- - - LOC_A101

&nbsp;               <img src="../_resources/ec31d6bfbdb1d228173dbe3955ea7d20.png" alt="ec31d6bfbdb1d228173dbe3955ea7d20.png" width="112" height="131" class="jop-noMdConv">

- - - PX_CAT_G1V2

&nbsp;               <img src="../_resources/3351d9e60ec27d3533b3c86a5a2f7c09.png" alt="3351d9e60ec27d3533b3c86a5a2f7c09.png" width="263" height="205">

&nbsp;

&nbsp;

&nbsp;