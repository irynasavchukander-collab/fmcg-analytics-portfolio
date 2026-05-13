
-- FILE: 02_country_cost_decomposition.sql
-- BUSINESS QUESTION: Why do some countries have low margins?
-- INSIGHT: Shows where the money "leaks" - COGS, logistics,
--          marketing, or excessive discounts - to know what exactly to fix.
-- RECOMMENDATION: If the problem is logistics - change the delivery partner.
--                 If it is COGS - renegotiate with the supplier.
--                 If it is marketing - check campaign ROI.
--                 If discounts >20% - revise the promo strategy.
-- ADDITIONAL: Displays each country's share of total sales
--             to assess the scale of the problem in the portfolio.
-- ============================================================

WITH country_metrics AS (
    SELECT
        Country,
        Region,
        ROUND(SUM(Gross_Sales_USD), 2)                                      AS Gross_sales,
        ROUND(SUM(Profit_USD), 2)                                           AS Total_profit,
        ROUND(AVG(Profit_Margin_Pct), 2)                                    AS Avg_margin_pct,
        ROUND(SUM(COGS_USD)            / SUM(Gross_Sales_USD) * 100, 2)     AS Cogs_share_pct,
        ROUND(SUM(Logistics_Cost_USD)  / SUM(Gross_Sales_USD) * 100, 2)     AS Logistics_share_pct,
        ROUND(SUM(Marketing_Spend_USD) / SUM(Gross_Sales_USD) * 100, 2)     AS Marketing_share_pct,
        ROUND(AVG(Discount_Pct) , 2)                                        AS Avg_discount_pct
     FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    GROUP BY Country, Region
),

portfolio_totals AS (
    SELECT SUM(Gross_Sales_USD) AS Total_portfolio_sales
    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
),

ranked AS (
    SELECT cm.*,
           RANK() OVER (ORDER BY Avg_margin_pct ASC) AS Margin_rank,

           -- Primary loss driver
           CASE
               WHEN Cogs_share_pct >= Logistics_share_pct
                AND Cogs_share_pct >= Marketing_share_pct
               THEN 'High COGS - Renegotiate with supplier'

               WHEN Logistics_share_pct >= Cogs_share_pct
                AND Logistics_share_pct >= Marketing_share_pct
               THEN 'High logistics - Switch logistics provider'
               WHEN Marketing_share_pct >= Cogs_share_pct
                AND Marketing_share_pct >= Logistics_share_pct
               THEN 'High marketing - Check campaign ROI'

               ELSE 'Mixed - full audit'
           END AS Loss_driver,

           -- Independent discount indicator
           CASE
               WHEN Avg_discount_pct > 20 THEN 'Excessive discounts'
               WHEN Avg_discount_pct BETWEEN 15 AND 20 THEN 'Risky discounts'
               ELSE 'Normal discounts'
           END AS Discount_flag,

           -- Share of total sales by country 
           ROUND(cm.gross_sales / pt.total_portfolio_sales * 100, 2) AS Sales_share_pct

    FROM country_metrics cm
    CROSS JOIN portfolio_totals pt
)

SELECT
    Country, Region, Gross_sales, Total_profit,
     Cogs_share_pct, Logistics_share_pct,
    Marketing_share_pct, Avg_discount_pct,
    Sales_share_pct,Avg_margin_pct, Margin_rank, Loss_driver, Discount_flag
FROM ranked
WHERE Margin_rank <= 5
ORDER BY Avg_margin_pct DESC;