# Discussion 4.1: Canvas Post Draft

**Data provided by the U.S. Census Bureau (via FRED: `MRTSSM448USN`).**  
Following up on my Module 3 dynamic regression Seasonal ARIMA model for **U.S. Retail Sales: Clothing and Clothing Accessories Stores (NAICS 448)**, I investigated whether variance-stabilizing data transformations (comparing **Guerrero Box-Cox** vs. **Natural Log** vs. **Untransformed Sales**) improve forecasting accuracy and model stability. In addition, I evaluated multi-period robustness using **Rolling-Origin Time Series Cross-Validation** via `stretch_tsibble()`.

---

### 1. Re-statement of Module 3 Model

In Module 3, my final selected forecasting model was an **Intervention Dynamic Regression Seasonal ARIMA** fitted on natural log-transformed monthly sales with an indicator variable for the spring 2020 COVID-19 pandemic shutdown:  
$$\ln(Y_t) = \beta_0 \cdot \text{covid\_lockdown}_t + \eta_t, \quad \eta_t \sim \text{ARIMA}(1,0,2)(0,1,1)_{12}$$

---

### 2. Transformation Decision & Clues

Retail apparel sales exhibit severe **multiplicative seasonality and expanding variance (heteroscedasticity)**:
* In 1992, the December holiday spike was $\$3.1\text{B}$ above baseline sales ($\approx \$6.7\text{B}$ baseline to $\$9.8\text{B}$ peak).
* By 2024–2025, baseline sales reached $\$23\text{B}$ and the December surge exceeded $\$38\text{B}$—a seasonal swing of over $\$15\text{B}$.
* When fitting an untransformed SARIMA model directly on raw sales, the residuals exhibit non-constant variance and fail the **Ljung-Box white noise portmanteau test** ($Q^* = 38.50, \text{dof} = 4, p = 0.0077 < 0.05$).

Using Guerrero’s (1993) optimization method, I identified an optimal Box-Cox parameter of **$\lambda = 0.418$**:
$$w_t = \frac{y_t^{0.418} - 1}{0.418}$$
Because $\lambda = 0.418$ lies between a log ($\lambda = 0$) and square root ($\lambda = 0.5$) transformation, it stabilizes the expanding seasonal amplitude into uniform seasonal bands across all 34 years without over-compressing holiday peaks.

*(Attach Figure 1: `transformation_series_comparison.png`)*

---

### 3. Re-fit and Validation (Path A & Path B)

#### Path A: Re-estimation on Transformed Data & Parameter Interpretation

Re-estimating the dynamic regression SARIMA under Guerrero Box-Cox ($\lambda = 0.418$) produced notable parameter improvements:
* **Moving Average Stability:** Under natural log, the non-seasonal $\text{MA}(1)$ parameter was $\theta_1 = -0.978$ ($\text{s.e.} = 0.0603$), dangerously close to the unit circle non-invertibility boundary ($|\theta| = 1.0$). Under Box-Cox ($\lambda = 0.418$), $\theta_1$ shifted to **$-0.7590$** ($\text{s.e.} = 0.0598$), moving comfortably inside the invertible region.
* **Residual White Noise:** Residual variance stabilized ($\sigma^2 = 0.0277$), and the model cleanly passed the Ljung-Box test ($Q^* = 24.73, \text{dof} = 4, p = 0.2119 > 0.05$), improving upon the log model ($p = 0.1172$).
* **COVID Lockdown Impact:** The intervention parameter scaled appropriately to $\beta = -3.220$ ($t = -36.6$), cleanly capturing the lockdown disruption.

```text
Model Parameters Comparison:

1. Untransformed SARIMA(1,0,2)(0,1,1)[12] + COVID:
   ar1 = 0.8828, ma1 = -0.5189, ma2 = 0.1439, sma1 = -0.6111, covid = -12.6544, drift = 0.4541
   Ljung-Box Q* = 38.50 (p = 0.0077 -> FAILS White Noise)

2. Module 3 Natural Log SARIMA(1,0,2)(0,1,1)[12] + COVID:
   ar1 = 0.8694, ma1 = -0.9784, ma2 = 0.4594, sma1 = -0.7505, covid = -1.2848, drift = 0.0287
   Ljung-Box Q* = 27.68 (p = 0.1172 -> PASSES White Noise)

3. Re-estimated Box-Cox (lambda = 0.418) SARIMA(1,0,2)(0,1,1)[12] + COVID:
   ar1 = 0.8806, ma1 = -0.7590, ma2 = 0.3304, sma1 = -0.7771, covid = -3.2203, drift = 0.0896
   Ljung-Box Q* = 24.73 (p = 0.2119 -> PASSES White Noise)
```

#### Holdout Test Set Accuracy (Sep 2025 – Aug 2026, 12 Months):

* **Ensemble (Simple Average of All 3):** Test RMSE = **\$0.482B** | Test MAE = **\$0.371B** | Test MAPE = **1.44%**
* **Guerrero Box-Cox ($\lambda = 0.418$):** Test RMSE = **\$0.541B** | Test MAE = **\$0.436B** | Test MAPE = **1.68%**
* **Module 3 Natural Log ($\lambda = 0$):** Test RMSE = **\$0.592B** | Test MAE = **\$0.459B** | Test MAPE = **1.71%**
* **Untransformed Sales ($\lambda = 1$):** Test RMSE = **\$0.707B** | Test MAE = **\$0.595B** | Test MAPE = **2.19%**

Among individual specifications, Box-Cox achieved the lowest forecasting error across all metrics—an **8.6% RMSE reduction** over log and a **23.5% RMSE reduction** over untransformed—while averaging all three models into a simple ensemble reduced holdout RMSE further to **\$0.482B** (`1.44%` MAPE).

*(Attach Figure 2: `clothing_sales_boxcox_overlay_forecast.png`)*

#### Path B: Post-COVID Rolling-Origin Time Series Cross-Validation (`stretch_tsibble()`)

To evaluate multi-period stability after the pandemic shock without pre-2020 rank deficiency on COVID indicator variables, I conducted post-COVID rolling-origin cross-validation via `stretch_tsibble(.init = 360, .step = 1)` across 33 monthly origins (Dec 2021 – Aug 2024; testing Jan 2022 – Aug 2025 over horizons $h = 1 \dots 12$) using month-specific COVID indicators (`covid_mar + covid_apr + covid_may`) so asymmetric 2020 drops (`-51%`, `-88%`, `-63%`) do not distort multiplicative baselines across seasonal differencing:

* **Ensemble (Simple Average of All 3):** CV RMSE = **\$0.669B** | CV MAE = **\$0.519B** | CV MAPE = **2.25%**
* **Guerrero Box-Cox ($\lambda = 0.418$):** CV RMSE = **\$0.671B** | CV MAE = **\$0.522B** | CV MAPE = **2.26%**
* **Natural Log ($\lambda = 0$):** CV RMSE = **\$0.713B** | CV MAE = **\$0.553B** | CV MAPE = **2.42%**
* **Untransformed Sales ($\lambda = 1$):** CV RMSE = **\$0.724B** | CV MAE = **\$0.564B** | CV MAPE = **2.38%**

Giving each spring 2020 lockdown month its own indicator removes multiplicative baseline distortion so both transformed models outperform Untransformed on RMSE and MAE (`Guerrero Box-Cox` leads individual models at `$0.671B`), while the **simple average ensemble** ranks 1st overall across CV RMSE (**\$0.669B**), MAE (**\$0.519B**), and MAPE (**2.25%**).

*(Attach Figure 3: `cross_validation_rolling_origin_comparison.png`)*

---

### 4. Insights

1. **Variance Stabilization Is Essential:** In series with strong multiplicative seasonality, untransformed modeling violates homoscedasticity and produces autocorrelated residuals that fail the Ljung-Box test ($p = 0.0077$).
2. **Structural Parameter Health:** Moving from log ($\lambda = 0$) to Box-Cox ($\lambda = 0.418$) shifted $\text{MA}(1)$ away from the non-invertibility boundary ($\theta_1 = -0.978 \to -0.759$) and yielded cleaner white noise residuals ($p = 0.212$).
3. **Transformation & Ensemble Gains:** Box-Cox delivered the best single-model accuracy on both the 2025–2026 holdout (`$0.541B` RMSE) and post-COVID CV (`$0.671B` RMSE) once COVID shocks were separated by month, while averaging forecasts across all three transformation scales further lowered out-of-sample error in both regimes (`$0.482B` holdout RMSE; `$0.669B` CV RMSE).

---

### 5. Future Experiment

As a next step, I would re-specify seasonal/non-seasonal ARIMA orders (`pdq`/`PDQ`) alongside the month-specific COVID indicators and additional spring 2021 stimulus rebound controls, and test exogenous macroeconomic indicators—such as the **University of Michigan Consumer Sentiment Index (`UMCSENT`)**—within the dynamic regression framework.

---

### References

* Box, G. E., & Cox, D. R. (1964). An analysis of transformations. *Journal of the Royal Statistical Society: Series B (Methodological)*, 26(2), 211-243.
* Guerrero, V. M. (1993). Time-series analysis supported by power transformations. *Journal of Forecasting*, 12(1), 37-48. https://doi.org/10.1002/for.3980120104
* Hyndman, R. J., & Athanasopoulos, G. (2021). *Forecasting: Principles and practice* (3rd ed.). OTexts: Melbourne, Australia. https://otexts.com/fpp3/
* U.S. Census Bureau. (2026). *Retail sales: Clothing and clothing accessories stores (MRTSSM448USN)* [Data set]. Federal Reserve Bank of St. Louis (FRED). https://fred.stlouisfed.org/series/MRTSSM448USN

---

### Peer Response Suggestions & Templates (For Day 7)

#### Peer Reply Option 1: Suggesting Alternative Transformation or Diagnostic
> "Great analysis on [Classmate's Dataset]! I noticed that your series also displays expanding seasonal swings as the level rises. While you tested [Log / None], have you considered running Guerrero's method (`features(..., guerrero)`) to estimate an optimal Box-Cox parameter? In my apparel retail dataset, tuning $\lambda$ to $0.418$ moved my moving average parameters away from the non-invertibility boundary ($|\theta| \approx 1$) and lowered my holdout RMSE by over 8% compared to log. It might also help resolve the lingering residual autocorrelation you observed at lag [X]."

#### Peer Reply Option 2: Commenting on Cross-Validation Design
> "I really appreciated your cross-validation setup using `stretch_tsibble()`. One interesting aspect to consider is whether an expanding rolling origin or a fixed sliding window (`slide_tsibble()`) would be more informative for your series. With retail data spanning 30+ years, older structural regimes can sometimes bias modern forecasts. Did you notice if your forecast errors varied significantly between earlier CV folds versus the more recent post-pandemic periods? Expanding the horizon analysis beyond $h=1$ could also reveal if the transformation advantage compounds over longer horizons."
