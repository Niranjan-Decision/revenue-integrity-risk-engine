/*******************************************************************************
PROJECT: Strategic Revenue Integrity & Risk Simulation Engine
PHASE: 3 - Advanced Logic & Financial Enrichment
OBJECTIVE: Transform raw transactions into actionable financial intelligence.
AUTHOR : Niranjan Raj Paudel
*******************************************************************************/

USE retail_intelligence;
SET SQL_SAFE_UPDATES = 0;

-- STEP 1: LOGIC VALIDATION
-- Removing zero-price rows to ensure Average Price and Revenue math is not distorted.
DELETE FROM fact_sales_transactions 
WHERE Price = 0 OR Price IS NULL;

-- STEP 2: CATEGORICAL ENRICHMENT (Flagging Returns)
-- Adding a binary flag to distinguish between successful sales and cancellations.
ALTER TABLE fact_sales_transactions 
ADD COLUMN is_cancelled TINYINT(1) DEFAULT 0;

UPDATE fact_sales_transactions 
SET is_cancelled = 1 
WHERE Invoice LIKE 'C%';

-- STEP 3: FINANCIAL ENRICHMENT (Line Total)
-- Calculating the exact value of every row using high-precision Decimal(15,2).
ALTER TABLE fact_sales_transactions 
ADD COLUMN line_total DECIMAL(15,2);

UPDATE fact_sales_transactions 
SET line_total = ROUND(Quantity * Price, 2);

-- STEP 4: REVENUE GAP AUDIT 
-- Quantifying the total "Leakage" from the business.
SELECT 
    is_cancelled, 
    COUNT(*) AS total_rows,
    ROUND(SUM(line_total), 2) AS total_revenue_value
FROM fact_sales_transactions
GROUP BY is_cancelled;

-- STEP 5: TOXIC PRODUCT IDENTIFICATION 
-- Identifying the top 10 drivers of revenue loss.
SELECT 
    Description, 
    StockCode,
    COUNT(*) AS return_count,
    ROUND(SUM(line_total), 2) AS total_loss_value
FROM fact_sales_transactions
WHERE is_cancelled = 1
GROUP BY Description, StockCode
ORDER BY total_loss_value ASC 
LIMIT 10;