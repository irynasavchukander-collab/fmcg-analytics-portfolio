-- FILE: 05_b2b_vs_b2c.sql
-- BUSINESS QUESTION: Which segment is more profitable: B2B or B2C?
-- INSIGHT: B2B = larger orders but higher discounts compress margin
-- RECOMMENDATION: Allocate sales and marketing resources to the segment with better margin efficiency
-- ====================================================================================================

-- STEP 1: Global benchmark across ALL orders — not just per segment for AVG margin/discount
WITH global_benchmark AS (
    SELECT
        ROUND(AVG(Profit_Margin_Pct), 2)  AS global_avg_margin,
        ROUND(AVG(Discount_Pct), 2) AS global_avg_discount
    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
),

-- STEP 2:  Aggregate all key metrics per customer segment

segment_summary AS (
    SELECT
        Customer_Type,

        --  Volume metrics 
        COUNT(Order_ID)                                                      AS total_orders,
        ROUND(AVG(Units_Sold),0)                                             AS avg_units_per_order,
        ROUND(AVG(Gross_Sales_USD), 2)                                       AS avg_order_value,
        ROUND(SUM(Gross_Sales_USD), 2)                                       AS total_gross_sales,

        --  Profitability metrics 
        ROUND(AVG(Profit_Margin_Pct), 2)                                     AS avg_margin_pct,
        ROUND(SUM(Profit_USD), 2)                                            AS total_profit,

        -- Cost metrics 
        ROUND(AVG(Discount_Pct), 2)                                          AS avg_discount_pct,
        ROUND(AVG(Logistics_Cost_USD), 2)                                    AS avg_logistics_per_order,
        ROUND(SUM(COGS_USD) / SUM(Gross_Sales_USD) * 100, 2)                 AS cogs_share_pct,

        --  Marketing efficiency , how much marketing spend per $1 of profit 
        -- NULLIF protects against division by zero if we have "-" in profit
       
        ROUND(SUM(Marketing_Spend_USD) / NULLIF(SUM(Profit_USD), 0) * 100, 2) AS marketing_to_profit_ratio,

        -- EN: Risk metric , share of loss-making orders per segment
        ROUND(COUNTIF(Profit_USD < 0) * 100.0 / COUNT(Order_ID), 1)          AS loss_rate_pct

    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    GROUP BY Customer_Type
)

-- STEP 3: Final output comparing each segment against global benchmark
SELECT
    s.Customer_Type,
    s.total_orders,
    s.avg_units_per_order,
    s.avg_order_value,
    s.total_gross_sales,
    s.avg_margin_pct,
    s.total_profit,
    s.avg_discount_pct,
    s.avg_logistics_per_order,
    s.cogs_share_pct,
    s.marketing_to_profit_ratio,
    s.loss_rate_pct,

    --  How far is this segment from the global average margin?
    -- Positive = above global average 
    ROUND(s.avg_margin_pct - g.global_avg_margin, 2)    AS margin_vs_global,
    ROUND(s.avg_discount_pct - g.global_avg_discount, 2) AS discount_vs_global,

    --  Segment efficiency score margin divided by discount pressure
    -- Higher = better margin per unit of discount given
    ROUND(s.avg_margin_pct / NULLIF(s.avg_discount_pct, 0), 2) AS margin_per_discount_unit

FROM segment_summary s
CROSS JOIN global_benchmark g
ORDER BY s.avg_margin_pct DESC;