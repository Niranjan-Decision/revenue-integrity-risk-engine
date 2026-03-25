/******************************************************************
PROJECT: Strategic Revenue Integrity & Risk Simulation Engine
PHASE: 1 - Ingestion & Infrastructure
OBJECTIVE: Database initialization and high-volume CSV bulk loading.
AUTHOR: Niranjan Raj Paudel
******************************************************************/

-- 1. Create the database environment
CREATE DATABASE IF NOT EXISTS retail_intelligence;
USE retail_intelligence;

-- 2. Define the Raw Landing Zone (Bronze Layer)
-- Using VARCHAR for dates and IDs initially to ensure 100% ingestion success
CREATE TABLE raw_retail (
    Invoice VARCHAR(255),
    Stockcode VARCHAR(255),
    Description VARCHAR(255),
    Quantity INT,
    Invoicedate VARCHAR(255), 
    Price DECIMAL(10,2),
    Customer_id VARCHAR(255),
    Country VARCHAR(255)
);

-- 3. Bulk Load Strategy
-- Note: Requires secure_file_priv access for high-speed local ingestion
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/online_retail_II.csv' 
INTO TABLE raw_retail 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. Initial Audit
-- Target: ~1,067,371 rows
SELECT 
    COUNT(*) AS total_rows, 
    COUNT(DISTINCT Country) AS unique_countries,
    SUM(Quantity) AS total_units_moved
FROM raw_retail;