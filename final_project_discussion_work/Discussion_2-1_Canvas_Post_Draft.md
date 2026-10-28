# Discussion 2.1: Preliminary Analysis of a Proposed Dataset

**Author:** Jordan Blackman  
**Dataset:** California New Private Housing Units Authorized by Building Permits (`CABPPRIV`)  
**Data Source:** U.S. Census Bureau & HUD via Federal Reserve Bank of St. Louis (FRED)  
**Image to Attach:** `california_housing_permits_tslm_forecast.png`

---

### [Canvas Discussion Post Text]

**Data provided by the U.S. Census Bureau and the U.S. Department of Housing and Urban Development (via FRED).**  
The dataset reports monthly new private housing units authorized by building permits from 1988 through 2026. Building permits serve as an officially recognized leading economic indicator for residential construction starts. For this discussion, I've narrowed the analysis to California (`CABPPRIV`), partitioning the series to train on data through December 2023 and evaluate out-of-sample forecasts on 2024–2026.

I attempted a TSLM model so that I could add predictor variables for month of year, secular trend, and a structural break indicator for the post-2008 subprime crisis.

#### Model Parameters
```text
Series: permits 
Model: TSLM 

Residuals:
    Min      1Q  Median      3Q     Max 
-9448.9 -2847.1  -436.6  2066.2 13320.4 

Coefficients:
                  Estimate Std. Error t value Pr(>|t|)    
(Intercept)       9188.329    747.576  12.291  < 2e-16 ***
trend()              8.215      2.878   2.854  0.00453 ** 
monthFeb            88.591    908.939   0.097  0.92240    
monthMar          2258.959    908.952   2.485  0.01334 *  
monthApr          2049.549    908.975   2.255  0.02466 *  
monthMay          2308.723    909.007   2.540  0.01145 *  
monthJun          3727.897    909.048   4.101 4.95e-05 ***
monthJul          1457.904    909.098   1.604  0.10954    
monthAug          1855.245    909.158   2.041  0.04192 *  
monthSep           867.557    909.226   0.954  0.34055    
monthOct          1683.137    909.035   1.852  0.06479 .  
monthNov           330.922    909.067   0.364  0.71602    
monthDec          1498.235    909.108   1.648  0.10010    
is_post_2008TRUE -6203.622    726.364  -8.541 2.51e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 3856 on 418 degrees of freedom
Multiple R-squared: 0.2997, Adjusted R-squared: 0.2780
F-statistic: 13.76 on 13 and 418 DF, p-value: < 2.22e-16
```

We can see that in June the model predicts over 3,727 additional building permits authorized compared to January, reflecting California's peak summer building season. Additionally, the post-2008 indicator reveals a statistically significant downward level shift of over 6,200 authorized permits per month following the Great Financial Crisis.

*(Attach: `california_housing_permits_tslm_forecast.png`)*

Steps in forecast reflect the month predictor variable in lieu of simple seasonality. Incorporating the 2008 structural break improved test RMSE from 2,094 to 1,169. However, TSLM may not be the best choice for this dataset, and it's worth noting an auto-selected `ETS()` model (`ETS(M,Ad,M)`) performed better than all the TSLM models I tried, achieving a test RMSE of 1,083 and a MAPE of 8.68%.

---

#### Reference
U.S. Census Bureau, & U.S. Department of Housing and Urban Development. (2024). *New private housing units authorized by building permits for California (CABPPRIV)* [Data set]. Federal Reserve Bank of St. Louis (FRED). https://fred.stlouisfed.org/series/CABPPRIV
