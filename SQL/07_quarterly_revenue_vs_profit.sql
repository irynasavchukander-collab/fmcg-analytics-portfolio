-- ============================================================
-- FILE: 07_quarterly_revenue_vs_profit.sql
-- BUSINESS QUESTION: Do revenue peaks align with profit peaks?
-- RECOMMENDATION: Plan promo calendar based on margin peaks
-- ============================================================

-- STEP 1: One CTE — all aggregations per quarter
WITH quarterly AS (
    SELECT
        Year,
        Quarter,
        SUM(Gross_Sales_USD)                                                AS gross_sales,
        SUM(Net_Revenue_USD)                                                AS net_revenue,
        SUM(Profit_USD)                                                     AS total_profit,
        SUM(Gross_Sales_USD) - SUM(Net_Revenue_USD)                         AS discount_impact,
        SUM(COGS_USD) + SUM(Logistics_Cost_USD) + SUM(Marketing_Spend_USD)  AS total_costs,

        -- EN: Aggregate ratio — more accurate than AVG(Profit_Margin_Pct)
        --     weights by order size not order count
        SAFE_DIVIDE(SUM(Profit_USD), SUM(Net_Revenue_USD)) * 100            AS avg_margin_pct,
        AVG(Discount_Pct)                                                   AS avg_discount_pct

    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    GROUP BY Year, Quarter
)

-- STEP 2: Window functions on top of aggregated CTE
--  All rankings and deltas calculated here — keeps CTE clean

SELECT
    Year,
    Quarter,
    ROUND(gross_sales, 2)      AS gross_sales,
    ROUND(net_revenue, 2)      AS net_revenue,
    ROUND(total_profit, 2)     AS total_profit,
    ROUND(avg_margin_pct, 2)   AS avg_margin_pct,
    ROUND(avg_discount_pct, 2) AS avg_discount_pct,
    ROUND(discount_impact, 2)  AS discount_impact,
    ROUND(total_costs, 2)      AS total_costs,

    --  QoQ - sequential trend across years (Q1 2024 vs Q4 2023)
   
    ROUND(total_profit
        - LAG(total_profit) OVER (ORDER BY Year, Quarter), 2)              AS profit_delta_qoq,

    --  YoY - same quarter vs same quarter previous year
    --  PARTITION BY Quarter ensures Q1-Q1, Q2-Q2 comparison

    ROUND(total_profit
        - LAG(total_profit) OVER (PARTITION BY Quarter ORDER BY Year), 2)  AS profit_delta_yoy,

    --  Dual ranking - does best revenue quarter = best profit quarter?
    
    DENSE_RANK() OVER (ORDER BY gross_sales DESC)                           AS rank_by_revenue,
    DENSE_RANK() OVER (ORDER BY total_profit DESC)                          AS rank_by_profit,

    --  Rank gap - how far revenue rank deviates from profit rank
    --    Positive = overrated by revenue / Negative =  undervalued
    
    DENSE_RANK() OVER (ORDER BY gross_sales DESC)
    - DENSE_RANK() OVER (ORDER BY total_profit DESC)                        AS rank_gap,

    -- Flag quarters above/below annual average margin
    CASE
        WHEN avg_margin_pct > AVG(avg_margin_pct) OVER (PARTITION BY Year)
        THEN 'Above annual avg'
        ELSE 'Below annual avg'
    END                                                                     AS margin_vs_annual_avg

FROM quarterly
ORDER BY Year, Quarter;