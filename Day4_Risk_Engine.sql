/* =============================================================================
PROJECT: Strategic Revenue Integrity & Risk Simulation Engine
PHASE:  4 - Risk Intelligence Integration
OBJECTIVE: 
To transition from descriptive reporting (what happened) to strategic 
evaluation (efficiency & risk). This phase quantifies "Revenue Leakage" 
across three critical business dimensions—Geography, Customer Quality, 
and Product Profitability—using the Profit Efficiency Ratio (PER).
AUTHOR: Niranjan Raj Paudel
=============================================================================
*/

-- Step 1: GEOGRAPHIC PROFIT EFFICIENCY
-- Purpose: Evaluate market stability. A low PER indicates that the cost of 
-- operations (returns/cancellations) is consuming the revenue potential.

SELECT 
    country,
    COUNT(Invoice) AS total_order_volume,
    ROUND(SUM(line_total), 2) AS gross_potential_revenue,
    
    -- [REVENUE LEAKAGE] The absolute financial loss from failed transactions
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN ABS(line_total) ELSE 0 END), 2) AS revenue_leakage,
    
    -- [PROFIT EFFICIENCY RATIO (PER)]
    -- Tells us: "For every 1 AED booked, how much is actually retained?"
    ROUND((SUM(line_total) - SUM(CASE WHEN is_cancelled = 1 THEN ABS(line_total) ELSE 0 END)) / NULLIF(SUM(line_total), 0), 4) AS profit_efficiency_ratio

FROM fact_sales_transactions
GROUP BY country
HAVING total_order_volume > 100
ORDER BY revenue_leakage DESC;


-- Step 2: CUSTOMER SEGMENT QUALITY
-- Purpose: Isolate "Serial Returners." This identifies customers who generate 
-- high volume but destroy operational margins through excessive cancellations.

SELECT 
    customer_id,
    ROUND(SUM(line_total), 2) AS total_gross_spend,
    ROUND((SUM(line_total) - SUM(CASE WHEN is_cancelled = 1 THEN ABS(line_total) ELSE 0 END)) / NULLIF(SUM(line_total), 0), 4) AS customer_PER_score
FROM fact_sales_transactions
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING total_gross_spend > 2500 
ORDER BY customer_per_score ASC
LIMIT 10;


-- Step 3: PRODUCT RECOVERY STRATEGY
-- Purpose: Identify "Toxic Products." These are specific items that contribute 
-- the most to the 1.46M AED leakage gap, requiring immediate quality or logistics review.

SELECT 
    StockCode,
    Description,
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN ABS(line_total) ELSE 0 END), 2) AS lost_revenue
FROM fact_sales_transactions
GROUP BY StockCode, Description
ORDER BY lost_revenue DESC
LIMIT 15;

-- Step 4: the total financial damage caused by  top 15 "Toxic" products

SELECT SUM(total_lost_revenue) AS total_top_15_leakage
FROM (
    SELECT 
        StockCode,
        ROUND(SUM(CASE WHEN is_cancelled = 1 THEN ABS(line_total) ELSE 0 END), 2) AS total_lost_revenue
    FROM fact_sales_transactions
    GROUP BY StockCode
    ORDER BY total_lost_revenue DESC
    LIMIT 15
) AS top_products;

-- Here is the interesting part about this query
-- Finding: The "Concentrated Risk" Factor. 
-- Note: Top 5 products account for 947k AED of leakage, representing ~91% 
-- of the Top 15's total loss. This allows for a "Laser-Focused" recovery.

SELECT 
    StockCode,
    Description,
    ROUND(SUM(CASE WHEN is_cancelled = 1 THEN ABS(line_total) ELSE 0 END), 2) AS lost_revenue
FROM fact_sales_transactions
GROUP BY StockCode, Description
ORDER BY lost_revenue DESC
LIMIT 5;