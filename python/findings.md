### Performance Summary 

***Model result***
- MAE: $35.42 - average prediction error per order

- R2: 0.9268 - 92.7% of profit variance explained

- SMAPE: 33.8% - average relative error (high for small orders)

***Key Observation***
- Only COGS explains 75.8% of profit variance.
- Top‑2 features (COGS + Category) explain 87.2%.
- All other factors together — just 12.8%.
This means profit is almost entirely determined by what you sell and how much production costs, not by discount level, channel, or promo activity.

Forecast Q1 2026
Best combinations:  
- Beverages / Modern Trade / B2C: $147.01
- Personal Care / Modern Trade / B2C: $147.01
- Snacks / Online / B2B: $147.01

By category (average predicted profit):  
- Best: Snacks
- Worst: Beverages

By channel (average predicted profit):  
- Best: Modern Trade
- Worst: Distributor
  
 Note: Forecast is based on a baseline scenario without promotions and with median cost values — to be used as directional guidance.

### Methodological Note  — A/B Testing on Historical Data
This is an observational study based on historical transaction data, not a randomized controlled experiment.

Group sizes are unequal (37% vs 63%) because they reflect real business operations rather than experimental assignment.

Mann‑Whitney U and Bootstrap CI are both valid for unequal groups. The large sample sizes (6,741 and 11,499) provide sufficient statistical power for reliable conclusions.

Limitation: We cannot claim causation only that no‑promo orders are associated with higher profit. Confounding factors (seasonality, channel mix, product mix) may partially explain the difference.

The data already exist  we did not control how orders were assigned to groups:
- 6,741 no‑promo orders (37%)
- 11,499 promo orders (63%)

This simply reflects real business practice: most orders included some type of promotion.

Mann‑Whitney U — does not require equal groups ;

Bootstrap CI — does not require equal groups ;

Cohen’s d — accounts for group sizes in its formula ;

The only requirement: each group >= 30 observations.
Here we have 6,741 and 11,499 - both are large 


### Methodological Note - Forecasting 

***Why Random Forest (instead of Linear Regression or XGBoost)?*** 

- Profit data is non‑linear - COGS, discounts, and channel interactions are complex, which linear models miss.
- Mixed feature types - numerical (COGS_USD, Units_Sold) and categorical (Sales_Channel, Category). Random Forest handles both without extra preprocessing.
- Robust to outliers - EDA confirmed profit has extreme values (min −$637, max $2 723). RF averages across 100 trees, reducing outlier impact.
- Built‑in feature importance — the main business question is “what drives profit?” RF answers directly via feature_importances_

***Why not Linear Regression?*** 
Although Pearson correlation between COGS and Profit is high, the relationship has non‑linear thresholds (e.g., discount effect differs by channel - confirmed in A/B). Linear regression would underfit this structure.

***Why SMAPE (instead of only MAE or RMSE)?***
MAE = $35.42  
- Average absolute error in dollars.
- Easy to interpret: “we miss by $35 per order.”
- But $35 error on a $500 order is fine, while $35 error on a $40 order is critical.
- MAE does not scale with order size.

RMSE  
- Penalizes large errors more than MAE.
- Very sensitive to outliers ($2,723 orders).
- Can be misleading when outliers dominate.

SMAPE = 33.8%  
- Symmetric Mean Absolute Percentage Error.
- Formula: |actual − predicted| / ((|actual| + |predicted|) / 2).
- Scales with order size — fair for both small and large orders.
- Symmetric: treats over‑prediction and under‑prediction equally.
- 33.8% means on average we are off by +/- 34% of order value.

***Why is SMAPE high (33.8%) while R2 is strong (0.93)?***
This is a typical pattern in financial data:
- R2 = 0.93 shows the model explains 93% of profit variance across the full range of orders.
- SMAPE = 33.8% is driven by small‑profit orders.
(Example: actual = $10, predicted = $15 - SMAPE = 40%.
actual = $500, predicted = $480 - SMAPE = 4%.)
- Small orders dominate in count but not in business impact.
-  For strategic decisions (channel allocation, category investment) R2 = 0.93 is the relevant metric.
-  For per‑order pricing decisions, SMAPE = 33.8% is the relevant metric — signaling need for more granular data.

  
