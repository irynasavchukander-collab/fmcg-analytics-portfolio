# fmcg-analytics-portfolio
End-to-end FMCG analytics: SQL + Tableau + Python

> **Core Question:** Where does profit actually come from —
> and where is the business silently losing money?
> Project Overview
fmcg-analytics-portfolio/
│
├── README.md
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
├── images/
│   ├── dashboards/
│   └── charts/
│
└── tableau/
    └── dashboard_links.md


## Dataset

- **Source:** Kaggle FMCG Sales Dataset
- **Size:** 18,240 orders × 27 columns
- **Period:** January 2023 — December 2025
- **Geography:** 17 countries across 4 regions
- **Channels:** Wholesale, Distributor, Modern Trade, Online
- **Categories:** Beverages, Dairy & Breakfast, Household,
  Personal Care, Snacks

**Key financial columns:**
`Gross_Sales_USD` - `Discount_Pct` - `Net_Revenue_USD`
- `COGS_USD` - `Logistics_Cost_USD` - `Marketing_Spend_USD`
- `Profit_USD` - `Profit_Margin_Pct`

The analysis follows a full analytics workflow:
- **SQL (BigQuery)** — business questions and EDA
- **Tableau** — interactive dashboards for stakeholders
- **Python** — statistical validation and ML forecasting

Each tool answers a different layer of the same question:
SQL finds the patterns - Tableau makes them visible -
Python proves they are statistically real and explains why.

This cross-tool validation approach mirrors real analytics
teams where SQL analysts, BI developers, and data scientists
work on the same business problem from different angles.

## Key Findings Summary

```
─┐
│ FINDING 1 — COGS is the #1 profit driver (75.8%)       │
│ SQL Q6: all channels COGS-heavy 49–53%                 │
│ ML: COGS feature importance = 0.7578                   │
│ Action: renegotiate supplier contracts                  │
│         3% reduction = ~$500K additional profit        │
├─────────────────────────────────────────────────────────┤
│ FINDING 2 — No Promo outperforms ALL campaigns          │
│ Marketing ROI: No Promo = $3.17 vs Festival = $1.23    │
│ A/B Test: p=6.57e-53, median gap = $29.08/order        │
│ ML: is_promo importance = 0.002 (almost irrelevant)    │
│ Action: keep Loyalty Cashback, eliminate Festival       │
├─────────────────────────────────────────────────────────┤
│ FINDING 3 — B2B wins 8/9 metrics vs B2C                │
│ SQL Q5: B2B profit $2.67M vs B2C $636K                 │
│ B2B marketing ROI 2x better (39% vs 81%)               │
│ Action: protect B2B, fix B2C marketing efficiency      │
├─────────────────────────────────────────────────────────┤
│ FINDING 4 — Online channel does not pay for itself      │
│ SQL Q6: ROI $0.68 < $1.00 break-even                   │
│ A/B: largest promo damage (Cohen's d = 0.450)          │
│ Action: zero promo budget, set min order value         │
├─────────────────────────────────────────────────────────┤
│ FINDING 5 — Beverages is structurally unprofitable      │
│ SQL Q8: margin 12–17%, even peaks are "Risky"          │
│ A/B: strongest promo damage by category (d=0.290)      │
│ ML: worst predicted category Q1 2026                   │
│ Action: reprice +8–10% or exit promo activity          │
└─────────────────────────────────────────────────────────┘


```
