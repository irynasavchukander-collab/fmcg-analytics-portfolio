-- FILE: 06_channel_efficiency.sql
-- BUSINESS QUESTION: Which sales channel is most efficient
--                    after all operational costs?
-- RECOMMENDATION: Reallocate budget to channels with
--                 better profit-to-cost ratio
-- ============================================================

WITH channel_base AS (
    SELECT
        Sales_Channel,
        -- STEP 1: Volume 
        COUNT(Order_ID)                  AS total_orders,
        SUM(Gross_Sales_USD)             AS gross_sales,
        SUM(Profit_USD)                  AS total_profit,
        SUM(Logistics_Cost_USD)          AS total_logistics,
        SUM(Marketing_Spend_USD)         AS total_marketing,
        SUM(COGS_USD)                    AS total_cogs,
        AVG(Profit_Margin_Pct)           AS avg_margin_pct,
        COUNTIF(Profit_USD < 0)          AS loss_orders

    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    GROUP BY Sales_Channel
)

SELECT
    Sales_Channel,
    total_orders,
    ROUND(gross_sales, 2)                                                  AS gross_sales,
    ROUND(total_profit, 2)                                                 AS total_profit,
    ROUND(avg_margin_pct, 2)                                               AS avg_margin_pct,

    --  Cost breakdown as % of gross sales — shows WHERE money leaks
    ROUND(total_logistics  / gross_sales * 100, 2)                        AS logistics_share_pct,
    ROUND(total_marketing  / gross_sales * 100, 2)                        AS marketing_share_pct,
    ROUND(total_cogs       / gross_sales * 100, 2)                        AS cogs_share_pct,

    -- Absolute totals 
    ROUND(total_logistics, 2)                                              AS total_logistics,
    ROUND(total_marketing, 2)                                              AS total_marketing,

    -- Marketing ROI — profit per 1$ spent 
    ROUND(total_profit / NULLIF(total_marketing, 0), 2)                   AS profit_per_marketing_dollar,

    --  Risk - % of loss-making orders 
    ROUND(loss_orders * 100.0 / total_orders, 1)                          AS loss_rate_pct,

    --  DENSE_RANK — no gaps when channels share same margin
    DENSE_RANK() OVER (ORDER BY avg_margin_pct DESC)                       AS efficiency_rank,

    -- Marks for main cost driver per channel
    CASE
        WHEN total_logistics > total_marketing
         AND total_logistics > total_cogs   THEN 'Logistics-heavy'
        WHEN total_marketing > total_logistics
         AND total_marketing > total_cogs   THEN 'Marketing-heavy'
        ELSE                                     'COGS-heavy'
    END AS cost_driver

FROM channel_base
ORDER BY avg_margin_pct DESC;