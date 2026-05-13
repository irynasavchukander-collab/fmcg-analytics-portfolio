-- ============================================================
-- FILE: 03_loss_disguised_as_revenue.sql
-- BUSINESS QUESTION: Orders with high revenue but low/negative profit
-- RECOMMENDATION: Set minimum margin threshold for promo & large orders
-- ============================================================

--STEP 1: Define thresholds as variables
DECLARE high_val  INT64   DEFAULT 1200; -- orders above $1000 = high-value
DECLARE mid_val   INT64   DEFAULT 500;  -- orders above $500  = mid-value
DECLARE risky_pct FLOAT64 DEFAULT 0.12; -- margin below 12% = risky 

--STEP 2: Build base dataset with all calculated fields
WITH base AS (
    SELECT
        Order_ID, Order_Date, Country, Sales_Channel,   -- Core identifiers 
        Promotion_Type, Product_Category, Units_Sold,
        -- STEP 2a: Format financial fields
        ROUND(Gross_Sales_USD, 2)                            AS gross_sales,
        ROUND(Discount_Pct, 2)                               AS discount_pct,
        ROUND(Profit_USD, 2)                                 AS actual_profit,
        -- STEP 2b: Calculate margin % 
        ROUND(Profit_USD / Net_Revenue_USD * 100, 2)         AS margin_pct,
        -- STEP 2c: Calculate each order's share of total portfolio revenue
        ROUND(Gross_Sales_USD / SUM(Gross_Sales_USD) OVER () * 100, 4) AS revenue_share_pct,
         -- STEP 2d: Classify order risk level (3 tiers)
        CASE
            WHEN Profit_USD < 0                              THEN 'Loss-making'
            WHEN Profit_USD / Net_Revenue_USD < risky_pct    THEN 'Risky margin'
            ELSE                                                  'Normal'
        END AS risk_flag,
         -- STEP 2e: Classify order by size + profitability combined 
        CASE
            WHEN Gross_Sales_USD > high_val AND Profit_USD < 0                           THEN 'High-value loss'
            WHEN Gross_Sales_USD > mid_val  AND Profit_USD < 0                           THEN 'Mid-value loss'
            WHEN Gross_Sales_USD > high_val AND Profit_USD / Net_Revenue_USD < risky_pct THEN 'High-value risky'
            WHEN Gross_Sales_USD > mid_val  AND Profit_USD / Net_Revenue_USD < risky_pct THEN 'Mid-value risky'
            ELSE                                                                          'Healthy'
        END AS order_type

    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    --STEP 2f: Filter to relevant orders only (without small value)
    WHERE Gross_Sales_USD > mid_val
)
-- STEP 3: Final output with group-level metrics
-- * all values from base CTE
-- Share of each risk group from the total number of orders in the sample
-- COUNT OVER(PARTITION BY) — counts rows within each group without collapsing the table
-- COUNT OVER() — counts all rows in the sample

SELECT
    *,
    ROUND(COUNT(*) OVER (PARTITION BY risk_flag) * 100.0 / COUNT(*) OVER (), 1) AS risk_group_pct,
    -- STEP 3b: Average margin within each risk group
    -- Average margin within each risk group —
    -- shows how deep the problem is, not only how many such orders exist
    ROUND(AVG(margin_pct) OVER (PARTITION BY risk_flag), 2)                     AS avg_group_margin
FROM base
ORDER BY
-- STEP 4: Sort — worst orders first, then by revenue descending
-- Sorting: first the worst orders, within each group — from larger to smaller
-- CASE in ORDER BY allows setting a custom priority instead of alphabetical order

    CASE risk_flag
        WHEN 'Loss-making'  THEN 1 -- worst first
        WHEN 'Risky margin' THEN 2 -- risky second
        ELSE                     3 -- healthy last
    END,
    gross_sales DESC;  -- within group: largest orders first 