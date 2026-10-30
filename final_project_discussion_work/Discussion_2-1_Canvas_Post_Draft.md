# Discussion 2.1: Preliminary Analysis of a Proposed Dataset

**Author:** Jordan Blackman  
**Dataset:** California New Private Housing Units Authorized by Building Permits (`CABPPRIV`)  
**Data Source:** U.S. Census Bureau & HUD via Federal Reserve Bank of St. Louis (FRED)  
**Primary Image to Attach:** `california_housing_permits_ets_auto_10yr_history.png` (or `california_housing_permits_ets_forecast.png`)

---

### [Canvas Discussion Post Text]

**Data provided by the U.S. Census Bureau and the U.S. Department of Housing and Urban Development (via FRED).**  
The dataset reports monthly new private housing units authorized by building permits from 1988 through 2026. Building permits serve as an officially recognized leading economic indicator for residential construction starts. For this discussion, I've narrowed the analysis to California (`CABPPRIV`), partitioning the series to train on data through December 2023 and evaluate out-of-sample forecasts on 2024–2026.

I selected an automated Exponential Smoothing state space model (`ETS()`) to capture dynamic level adjustments, multiplicative annual seasonality, and a damped trend. I also attempted several Time Series Linear Models (`TSLM`) using trend, month factors, and structural breaks for comparison.

#### Model Parameters
```text
Series: permits 
Model: ETS(M,Ad,M) 

Smoothing parameters:
  alpha = 0.3002 (level smoothing)
  beta  = 0.0187 (trend smoothing)
  gamma = 0.0002 (seasonal smoothing)
  phi   = 0.9414 (damping parameter)

Initial states:
  l[0] = 22,553.37
  b[0] = -27.76
  sigma^2: 0.0277
  AICc: 8948.59, BIC: 9020.17
  In-sample Pseudo R-squared: 0.8899
```

The auto-selected $\text{ETS}(M, A_d, M)$ model specifies multiplicative errors ($M$), an additive damped trend ($A_d$), and multiplicative seasonality ($M$). The moderate $\alpha = 0.30$ allows the baseline level to update dynamically with macroeconomic shifts, while the damping parameter $\phi = 0.941$ gradually flattens the trend slope into the future, preventing unrealistic downward projections. The multiplicative seasonal component effectively captures how spring permit surges expand proportionally during high-volume building cycles.

*(Attach Plot: `california_housing_permits_ets_auto_10yr_history.png` or `california_housing_permits_ets_forecast.png`)*

The ETS forecast reliably captures the annual spring ramp-up (March–June) and winter contraction while projecting a stable baseline around 9,000–10,000 monthly permits, closely tracking the actual holdout data (dashed line). I also attempted several Time Series Linear Models (`TSLM`); while adding a post-2008 structural break dummy improved TSLM test RMSE from 2,094 to 1,169, the auto-selected `ETS()` model performed best overall, achieving the lowest out-of-sample test RMSE of 1,083 and a MAPE of 8.68%. This indicates that state-space exponential smoothing is substantially more robust than static linear regression for adapting to post-pandemic rate shifts and evolving economic baselines.

---

#### Reference
U.S. Census Bureau, & U.S. Department of Housing and Urban Development. (2024). *New private housing units authorized by building permits for California (CABPPRIV)* [Data set]. Federal Reserve Bank of St. Louis (FRED). https://fred.stlouisfed.org/series/CABPPRIV
