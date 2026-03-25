/******************************************************************
PROJECT: Strategic Revenue Integrity & Risk Simulation Engine
PHASE: 2 - Data Engineering & Gold Layer Hardening
OBJECTIVE: Transform Silver data into a deduplicated, indexed Gold Fact Table.
AUTHOR: Niranjan Raj Paudel
******************************************************************/

USE retail_intelligence;

-- ==========================================================
-- STEP 1: SILVER LAYER (Standardization & Cleaning)
-- ==========================================================
-- Create a fresh table to protect raw data integrity
-- Logic: TRIM/LOWER for matching, CASE for missing Customer IDs
DROP TABLE IF EXISTS cleaned_retail;
CREATE TABLE cleaned_retail AS
SELECT 
    Invoice,
    StockCode,
    TRIM(LOWER(Description)) AS Description, 
    Quantity,
    InvoiceDate, 
    Price,
    CASE 
        WHEN Customer_ID = '' OR Customer_ID IS NULL THEN 'Unknown' 
        ELSE Customer_ID 
    END AS Customer_ID,
    TRIM(LOWER(Country)) AS Country
FROM raw_retail;

-- ==========================================================
-- STEP 2: TEMPORAL TRANSFORMATIONS (Casting)
-- ==========================================================
-- Logic: Convert string dates to proper DATETIME objects for time-series analysis
ALTER TABLE cleaned_retail ADD COLUMN Invoice_Timestamp DATETIME;

SET SQL_SAFE_UPDATES = 0;
UPDATE cleaned_retail 
SET Invoice_Timestamp = STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s');

-- ==========================================================
-- STEP 3: INITIAL DEDUPLICATION (Memory-Efficient)
-- ==========================================================
-- Note: Pivoted to DISTINCT as ROW_NUMBER() exceeded local hardware limits
DROP TABLE IF EXISTS fact_sales_transactions;
CREATE TABLE fact_sales_transactions AS
SELECT DISTINCT 
    Invoice, StockCode, Description, Quantity, 
    Invoice_Timestamp, Price, Customer_ID, Country
FROM cleaned_retail
WHERE Price > 0;

-- ==========================================================
-- STEP 4: REPAIR SCRIPT (Resolving PK Violation & Truncation)
-- ==========================================================
-- Logic: GROUP BY aggregates split line items. 
-- ROUND() resolves Warning 1265 (Data Truncation) from AVG(Price).
DROP TABLE IF EXISTS fact_sales_transactions_perfect;
CREATE TABLE fact_sales_transactions_perfect AS
SELECT 
    Invoice, 
    StockCode, 
    MAX(Description) AS Description, 
    SUM(Quantity) AS Quantity,       
    Invoice_Timestamp, 
    ROUND(AVG(Price), 2) AS Price, -- Fix for Warning 1265            
    Customer_ID, 
    MAX(Country) AS Country          
FROM fact_sales_transactions
GROUP BY Invoice, StockCode, Invoice_Timestamp, Customer_ID;

-- Swap to the Perfected Table
DROP TABLE fact_sales_transactions;
RENAME TABLE fact_sales_transactions_perfect TO fact_sales_transactions;

-- ==========================================================
-- STEP 5: GOLD LAYER FINALIZATION (Constraints)
-- ==========================================================
-- Hardening the table schema for professional indexing
ALTER TABLE fact_sales_transactions 
MODIFY Invoice VARCHAR(255) NOT NULL,
MODIFY StockCode VARCHAR(255) NOT NULL,
MODIFY Invoice_Timestamp DATETIME NOT NULL;

-- Applying the Composite Primary Key
ALTER TABLE fact_sales_transactions 
ADD PRIMARY KEY (Invoice, StockCode, Invoice_Timestamp);



