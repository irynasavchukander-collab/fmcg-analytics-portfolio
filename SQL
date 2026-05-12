01_unprofitable_categories.sql

-- FILE: 01_unprofitable_categories.sql
-- BUSINESS QUESTION: Which categories are truly unprofitable?
-- INSIGHT: Gross sales may look good, but after COGS + logistics + marketing, category goes negative.
-- RECOMMENDATION: Review pricing or stop promoting loss-making categories.

SELECT Product_Category,
    COUNT(Order_ID)                                AS total_orders,
    ROUND(SUM(Gross_Sales_USD), 2)                 AS gross_sales,
    ROUND(SUM(COGS_USD), 2)                        AS total_cogs,
    ROUND(SUM(Logistics_Cost_USD), 2)              AS total_logistics,
    ROUND(SUM(Marketing_Spend_USD), 2)             AS total_marketing,
    ROUND(SUM(Profit_USD), 2)                      AS total_profit,
    ROUND(AVG(Profit_Margin_Pct), 2)               AS avg_margin_pct,
      --Category classification 
    CASE
        WHEN AVG(Profit_Margin_Pct) >= 20 THEN 'High margin'
        WHEN AVG(Profit_Margin_Pct) >= 5  THEN 'Medium margin'
        WHEN AVG(Profit_Margin_Pct) >= 0  THEN 'Low margin'
        ELSE 'Loss-making'
    END AS category_status
FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG` 
GROUP BY Product_Category
ORDER BY avg_margin_pct ASC; 
