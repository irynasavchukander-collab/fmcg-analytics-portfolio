--distribution data for 03_loss_disguised_as_revenu

SELECT
    ROUND(MIN(Gross_Sales_USD), 2)    AS min_order,
    ROUND(MAX(Gross_Sales_USD), 2)    AS max_order,
    ROUND(AVG(Gross_Sales_USD), 2)    AS avg_order,
    ROUND(STDDEV(Gross_Sales_USD), 2) AS stddev_order,

    -- Percentiles
    APPROX_QUANTILES(Gross_Sales_USD, 100)[OFFSET(25)] AS p25,
    APPROX_QUANTILES(Gross_Sales_USD, 100)[OFFSET(50)] AS p50_median,
    APPROX_QUANTILES(Gross_Sales_USD, 100)[OFFSET(75)] AS p75,
    APPROX_QUANTILES(Gross_Sales_USD, 100)[OFFSET(90)] AS p90,
    APPROX_QUANTILES(Gross_Sales_USD, 100)[OFFSET(95)] AS p95

FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`;
-- Small orders: Gross_Sales < 500
-- Mid-value orders: 500 ≤ Gross_Sales < 1200
-- High-value orders: Gross_Sales ≥ 1200



--distribution data for 03_loss_disguised_as_revenu
SELECT
    ROUND(MIN(Profit_Margin_Pct), 2)    AS min_margin,
    ROUND(MAX(Profit_Margin_Pct), 2)    AS max_margin,
    ROUND(AVG(Profit_Margin_Pct), 2)    AS avg_margin,

    APPROX_QUANTILES(Profit_Margin_Pct, 100)[OFFSET(10)] AS p10,
    APPROX_QUANTILES(Profit_Margin_Pct, 100)[OFFSET(25)] AS p25,
    APPROX_QUANTILES(Profit_Margin_Pct, 100)[OFFSET(50)] AS p50,
-- -- How many orders are actually loss-making

    ROUND(COUNTIF(Profit_USD < 0) * 100.0 / COUNT(*), 1)         AS loss_orders_pct,

 -- How many orders are less 10% margin

    ROUND(COUNTIF(Profit_Margin_Pct < 12) * 100.0 / COUNT(*), 1) AS below_12pct_margin

FROM `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
LIMIT 1
--So, setting 12% as the risk margin threshold is the optimal choice for your data. It creates a clear “signal group” (~1/5 of orders) that can be analyzed more deeply — for example, which categories, countries, or channels most often fall into this segment.