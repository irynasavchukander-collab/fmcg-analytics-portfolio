-- =======================================================================================================
-- FILE: 08_category_seasonality.sql
-- BUSINESS QUESTION: Do all categories peak simultaneously
--                    or have different seasonality patterns??
-- INSIGHT: Different seasonality enables better inventory
--          planning and targeted marketing calendar
-- RECOMMENDATION: Sync marketing campaigns with peak months per category — avoid one-size-fits-all promos

-- =======================================================================================================

-- STEP 1: Monthly aggregation per category and year
--  EXTRACT is used instead of Month_Name column
--     to ensure correct numeric sorting (1-12 not A-Z)

WITH monthly AS (
    SELECT
        Product_Category,
        EXTRACT(YEAR  FROM Order_Date) AS Year,
        EXTRACT(MONTH FROM Order_Date) AS Month,

        COUNT(Order_ID)                                                    AS total_orders,
        SUM(Gross_Sales_USD)                                               AS gross_sales,
        SUM(Profit_USD)                                                    AS total_profit,
        SUM(Net_Revenue_USD)                                               AS net_revenue,

        --  Aggregate ratio — more accurate than AVG(Profit_Margin_Pct)
        --     weights by order size not order count
        SAFE_DIVIDE(SUM(Profit_USD), SUM(Net_Revenue_USD)) * 100           AS avg_margin_pct,
        AVG(Discount_Pct)                                                  AS avg_discount_pct

    FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    GROUP BY Product_Category, Year, Month
),

-- STEP 2: Category-year benchmarks for seasonality classification
--  Calculated separately to keep monthly CTE clean
--     avg_sales_per_month = benchmark for Above/Below average flag
stats AS (
    SELECT
        Product_Category,
        Year,
        AVG(gross_sales)    AS avg_sales_per_month,
        AVG(avg_margin_pct) AS avg_margin_per_month,
        SUM(gross_sales)    AS total_sales_year,
        MAX(gross_sales)    AS max_sales_month
    FROM monthly
    GROUP BY Product_Category, Year
)

-- STEP 3: Final output with all seasonal metrics
--  JOIN monthly with stats to get benchmarks per row

SELECT
    m.Product_Category,
    m.Year,
    m.Month,
    m.total_orders,
    ROUND(m.gross_sales, 2)                                                AS gross_sales,
    ROUND(m.total_profit, 2)                                               AS total_profit,
    ROUND(m.avg_margin_pct, 2)                                             AS avg_margin_pct,
    ROUND(m.avg_discount_pct, 2)                                           AS avg_discount_pct,

    --  Share of this month in category's annual revenue
    ROUND(m.gross_sales / s.total_sales_year * 100, 2)                    AS month_share_pct,

    --  MoM delta — is category growing or declining month to month?
    ROUND(m.gross_sales- LAG(m.gross_sales) OVER (PARTITION BY m.Product_Category, m.Year ORDER BY m.Month), 2)                                                                        AS mom_sales_delta,

    --  Above/Below average flag per category per year
    CASE
        WHEN m.gross_sales > s.avg_sales_per_month THEN 'Above average'
        ELSE                                             'Below average'
    END                                                                    AS seasonality_flag,

    -- Peak flag — top 2 months per category per year
    --     DENSE_RANK used instead of RANK to avoid gaps
    --     when two months share the same gross_sales value
   
    CASE
        WHEN DENSE_RANK() OVER (PARTITION BY m.Product_Category, m.Year ORDER BY m.gross_sales DESC) <= 2
        THEN 'Peak month'
        ELSE 'Normal'
    END                                                                    AS peak_flag,

    --  Promo recommendation : 4-tier classification
    --     based on sales AND margin vs category benchmarks
    --     Answers: WHEN is the best time to run a promotion?
    CASE
        WHEN m.gross_sales   > s.avg_sales_per_month
         AND m.avg_margin_pct > s.avg_margin_per_month
        THEN 'Optimal — launch promo now'       -- high sales + high margin

        WHEN m.gross_sales   > s.avg_sales_per_month
         AND m.avg_margin_pct <= s.avg_margin_per_month
        THEN 'Risky — high volume low margin'   -- high sales but margin squeezed

        WHEN m.gross_sales   <= s.avg_sales_per_month
         AND m.avg_margin_pct > s.avg_margin_per_month
        THEN 'Opportunity — promo can boost'    -- good margin needs volume

        ELSE 'Hold — low season'                -- worst time for promos
    END                                                                    AS promo_recommendation

FROM monthly m
JOIN stats s
  ON m.Product_Category = s.Product_Category
 AND m.Year             = s.Year

ORDER BY m.Product_Category, m.Year, m.Month;
