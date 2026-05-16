# fmcg-analytics-portfolio
End-to-end FMCG analytics: SQL + Tableau + Python

# FMCG Sales & Profitability Analytics
### End-to-end analytics project: SQL · Tableau · Python

---

## Repository Structure

```
fmcg-analytics-portfolio/
│
├── README.md                        ←
├── SUMMARY.md                       
│
├── sql/
│   ├── 01_unprofitable_categories.sql
│   ├── 02_country_cost_decomposition.sql
│   ├── 03_loss_disguised_as_revenue.sql
│   ├── 04_sales_reps_ranking.sql
│   ├── 05_b2b_vs_b2c.sql
│   ├── 06_channel_efficiency.sql
│   ├── 07_quarterly_revenue_vs_profit.sql
│   ├── 08_category_seasonality.sql
│   └── findings.md
│
├── python/
│   ├── marketing_roi.ipynb
│   ├── ab_testing.ipynb
│   ├── forecasting.ipynb
│   └── findings.md
│
│
└── tableau/
    ├── screenshots
    └── dashboard_links.md
    └── note.md
```

---

## Dataset

| Parameter | Value |
|-----------|-------|
| Source | Kaggle FMCG Sales Dataset |
| Orders | 18,240 |
| Columns | 27 |
| Period | January 2023 — December 2025 |
| Countries | 17 across 4 regions |
| Channels | Wholesale, Distributor, Modern Trade, Online |
| Categories | Beverages, Dairy & Breakfast, Household, Personal Care, Snacks |

**Financial columns flow:**
```
Gross_Sales_USD
- - Discount_Pct
- - Net_Revenue_USD
- - COGS_USD
- - Logistics_Cost_USD
- - Marketing_Spend_USD
- = Profit_USD
- Profit_Margin_Pct
```

---

## Tech Stack

| Layer | Tool | Version |
|-------|------|---------|
|   SQL | Google BigQuery | Standard SQL |
| Visualization | Tableau Public | 2024.1 |
| Analysis | Python | 3.10+ |
| Notebook | Google Colab | — |
| Version Control | GitHub | — |

**Python dependencies:**
```
pandas
numpy
matplotlib
seaborn
scipy
sklearn
```

---

## SQL Queries — Block Overview

### Block A — Profitability (Q1–Q3)
Answers: *Where is the business losing money?*

| File | Business Question | Key Technique |
|------|-------------------|---------------|
| `01_unprofitable_categories.sql` | Which categories are loss-making after all costs? | `GROUP BY` + `CASE WHEN` profitability tiers |
| `02_country_cost_decomposition.sql` | Why do some countries have low margin? | `CTE` + `RANK()` + auto-diagnosis |
| `03_loss_disguised_as_revenue.sql` | Which large orders are secretly loss-making? | `DECLARE` variables + window functions + risk classification |

**Shared logic across Block A:**
```sql
-- Risk classification used in Q3 and master view
CASE
    WHEN Profit_USD < 0                              THEN 'Loss-making'
    WHEN Profit_USD / Net_Revenue_USD < risky_pct    THEN 'Risky margin'
    ELSE                                                  'Normal'
END AS risk_flag
```

---

### Block B — People & Channels (Q4–Q6)
Answers: *Who and what drives profitability?*

| File | Business Question | Key Technique |
|------|-------------------|---------------|
| `04_sales_reps_ranking.sql` | Who generates profit vs just revenue? | `DENSE_RANK()` + `CROSS JOIN` global benchmark + 2×2 profile matrix |
| `05_b2b_vs_b2c.sql` | Which customer segment is more profitable? | `CTE` + `AVG() OVER()` + efficiency index |
| `06_channel_efficiency.sql` | Which channel is most efficient after all costs? | `CTE` + cost decomposition + `DENSE_RANK()` + auto-diagnosis |

**Key design decision — Q4:**
```sql
-- DENSE_RANK used instead of RANK
-- RANK creates gaps: 1,1,3 - distorts rank_gap calculation
-- DENSE_RANK is continuous: 1,1,2 - gap of 5 = exactly 5 positions
DENSE_RANK() OVER (ORDER BY total_gross_sales DESC) AS rank_by_revenue,
DENSE_RANK() OVER (ORDER BY avg_margin_pct DESC)    AS rank_by_margin,
DENSE_RANK() OVER (ORDER BY total_gross_sales DESC)
- DENSE_RANK() OVER (ORDER BY avg_margin_pct DESC)  AS rank_gap
```

**Key design decision — Q5:**
```sql
-- AVG() OVER() replaces CROSS JOIN for global benchmark
-- Cleaner and avoids additional CTE
ROUND(avg_margin_pct - AVG(avg_margin_pct) OVER (), 2) AS margin_vs_global
```

---

### Block C — Seasonality & Trends (Q7–Q8)
Answers: *When does performance peak and why?*

| File | Business Question | Key Technique |
|------|-------------------|---------------|
| `07_quarterly_revenue_vs_profit.sql` | Do revenue peaks align with profit peaks? | `SAFE_DIVIDE` + `LAG()` QoQ and YoY + `DENSE_RANK() OVER (PARTITION BY Year)` |
| `08_category_seasonality.sql` | When should each category be promoted? | 3-CTE architecture + `JOIN on two keys` + 4-tier promo recommendation |

**Key design decision — Q7, two LAG() variants:**
```sql
-- QoQ: no PARTITION BY — Q1 2024 compared to Q4 2023
-- Gives full sequential trend without year breaks
LAG(total_profit) OVER (ORDER BY Year, Quarter) AS profit_delta_qoq,

-- YoY: PARTITION BY Quarter — Q1 2024 compared to Q1 2023
-- Removes seasonality for fair year-over-year comparison
LAG(total_profit) OVER (PARTITION BY Quarter ORDER BY Year) AS profit_delta_yoy
```

**Key design decision — Q8, JOIN on two keys:**
```sql
-- Without Year condition: Jan 2023 compares to 2024 avg - WRONG
-- With Year condition: Jan 2023 compares to 2023 avg - CORRECT
JOIN stats s
ON m.Product_Category = s.Product_Category
AND m.Year             = s.Year
```

**Why 3 CTEs in Q8:**
```
monthly - SUM per month (row = category + year + month)
stats   - AVG of monthly sums (row = category + year)
SQL cannot compute AVG(SUM()) in one query level
Each CTE handles exactly ONE aggregation level
```

---

## Python Notebooks — Overview

| Notebook | Method | Validates |
|----------|--------|-----------|
| `marketing_roi.ipynb` | ANOVA, Kruskal-Wallis, Bootstrap CI, Polynomial regression | SQL Q5, Q6 channel ROI differences |
| `ab_testing.ipynb` | Mann-Whitney U, Cohen's d, Bootstrap CI, per-group breakdown | SQL Q3 loss patterns, Q6 channel efficiency |
| `forecasting.ipynb` | Random Forest Regressor, Feature Importance | SQL Q6 COGS finding, Q8 category ranking |

**Why Mann-Whitney U not t-test:**
```python
# Shapiro-Wilk confirms non-normal distributions
# No Promo: W=0.7349, p=3.93e-37 - NOT normal
# Promo:    W=0.7072, p=1.67e-38 - NOT normal
# Mann-Whitney makes no distribution assumption - correct choice
```

**Why Random Forest not Linear Regression:**
```
Profit has non-linear relationships with COGS, discount, channel
Mixed feature types (numerical + categorical)
Robust to outliers (profit range: -$637 to +$2 723)
Built-in feature importance answers core business question
```

**Why SMAPE alongside MAE:**
```
MAE = $35.42 — absolute error, does not scale with order size
SMAPE = 33.8% — scales with order size, fair for small AND large orders
High SMAPE driven by small-profit orders
R2=0.93 is the relevant metric for strategic-level forecasting
```

---

## How to Run

**SQL (BigQuery):**
```
1. Upload fmcg_sales.csv to BigQuery
   Project: your-project-id
   Dataset: portfolio_FMCG
   Table:   SALES_FMCG

2. Replace project reference in each query:
   `my-project-portfolio-494809.portfolio_FMCG.SALES_FMCG`
    `your-project-id.your_dataset.SALES_FMCG`

3. Run queries in order 01 - 08
   Each query is self-contained
```

**Python (Google Colab):**
```
1. Upload fmcg_sales.csv to Google Drive
2. Open each notebook in Colab
3. Update file path in Cell 2:
   df = pd.read_csv('/content/drive/MyDrive/YOUR_PATH/fmcg_sales.csv')
4. Run all cells in order
```

**Tableau:**
```
1. Connect to fmcg_sales.csv as data source
   OR connect to BigQuery directly
2. See tableau/dashboard_links.md for published dashboards
```

---

## Author

**Iryna Savchuk** — Data Analyst
[LinkedIn](#) · [Tableau Public](https://public.tableau.com/app/profile/iryna.savchuk/vizzes) 
