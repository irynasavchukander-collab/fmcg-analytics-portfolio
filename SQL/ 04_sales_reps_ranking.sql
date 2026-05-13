-- FILE: 04_sales_reps_ranking.sql
-- BUSINESS QUESTION: Who actually generates profit vs just revenue?
-- INSIGHT: A top revenue rep may be the worst margin performer.
-- RECOMMENDATION: Add margin KPI alongside revenue targets.
-- =================================================================


-- CTI 1: Aggregate all key metrics per sales representative
WITH rep_stats AS (
    SELECT
        Sales_Person,

        -- STEP 1: Basic metrics "how much they sell-how profitably they sell"
        COUNT(Order_ID)                                                  AS total_orders,
        ROUND(SUM(Gross_Sales_USD), 2)                                   AS total_gross_sales,
        ROUND(SUM(Profit_USD), 2)                                        AS total_profit,
        ROUND(AVG(Profit_Margin_Pct), 2)                                 AS avg_margin_pct,
        ROUND(AVG(Discount_Pct) , 2)                                     AS avg_discount_pct,

        -- STEP 2: Risk metrics — how often they create losses 
        -- COUNTIF bertter COUNT(CASE WHEN ... END) 
        COUNTIF(Profit_USD < 0)                                          AS loss_orders_count,
        ROUND(COUNTIF(Profit_USD < 0) * 100.0 / COUNT(Order_ID), 1)     AS loss_rate_pct

    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    GROUP BY Sales_Person
),
-- CTE 2 
-- STEP 3:  Calculate ONE global average row across all reps
-- Used as benchmark to classify each rep into a quadrant
-- Formula: AVG(avg_discount_pct) = sum of all reps' avg discounts / number of reps
-- IMPORTANT — must return exactly ONE row for CROSS JOIN to work correctly
global_avg AS (
    SELECT
        AVG(avg_discount_pct) AS global_avg_discount,
        AVG(avg_margin_pct)   AS global_avg_margin
    FROM rep_stats
)

-- FINAL SELECT
-- Join rep metrics with global benchmark, add rankings and profiles

SELECT
    r.Sales_Person,
    r.total_orders,
    r.total_gross_sales,
    r.total_profit,
    r.avg_margin_pct,
    r.avg_discount_pct,
    r.loss_orders_count,
    r.loss_rate_pct,

    -- STEP 4: RANKINGS 
    -- who sells more - who sells better
    DENSE_RANK() OVER (ORDER BY r.total_gross_sales DESC)  AS rank_by_revenue,
    DENSE_RANK() OVER (ORDER BY r.avg_margin_pct DESC)     AS rank_by_margin,

    -- STEP 6: RANK GAP 
    -- The difference between revenue rank and margin rank
    -- Negative value = overrated (looks good by revenue, poor by margin)
    -- Positive value = underrated (looks average by revenue, great by margin)
    DENSE_RANK() OVER (ORDER BY r.total_gross_sales DESC)
    - DENSE_RANK() OVER (ORDER BY r.avg_margin_pct DESC)   AS rank_gap,

   -- STEP 7: PROFILE CLASSIFICATION
   -- 2×2 matrix based on discount vs global average AND margin vs global average
    CASE
        WHEN r.avg_discount_pct > g.global_avg_discount
         AND r.avg_margin_pct   < g.global_avg_margin
        THEN 'Discount abuser'    -- High discount + low margin

        WHEN r.avg_discount_pct <= g.global_avg_discount
         AND r.avg_margin_pct    > g.global_avg_margin
        THEN 'Top performer'      -- Low discount + high margin

        WHEN r.avg_discount_pct > g.global_avg_discount
         AND r.avg_margin_pct   >= g.global_avg_margin
        THEN 'Volume driver'      -- High discount + high margin

        ELSE 'Average performer'
    END AS rep_profile,

    -- STEP 8: Include global averages in output for Tableau reference lines
    ROUND(g.global_avg_discount, 2) AS global_avg_discount,
    ROUND(g.global_avg_margin, 2)   AS global_avg_margin

FROM rep_stats r
CROSS JOIN global_avg g   -- CROSS JOIN works correctly because global_avg returns exactly ONE row

ORDER BY rank_by_margin DESC; 