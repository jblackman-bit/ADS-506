# About This Application

### U.S. Retail Sales Time Series Analysis & Forecasting Dashboard
**Course:** ADS 506 — Applied Time Series Analysis  
**Assignment:** Module 5 — Data Storytelling with Shiny  
**Author:** Jordan Blackman  
**Date:** November 2026  
**AI Attribution:** Drafted and refined using **Gemini 3.8 Flash (High)** in compliance with the course academic integrity guidelines.

---

## 1. Project Background & Objective

This application provides an interactive decision-support and forecasting platform analyzing monthly U.S. retail sales from **January 1992 through August 2026** (416 continuous monthly observations). Developed as part of ADS 506 (Applied Time Series Analysis), the dashboard enables supply chain planners, category managers, and retail analysts to:
- Investigate sectoral demand dynamics across staple, discretionary, and housing-linked retail verticals.
- Compare nominal dollar revenues against **real purchasing volume** deflated by the Consumer Price Index (CPI).
- Dynamically estimate and compare competitive time series forecasting models (**TSLM**, **ETS state-space**, **Seasonal ARIMA**, and **Ensemble Combo**).
- Customize training and out-of-sample validation windows to rigorously evaluate forecast accuracy prior to forward deployment.
- Visualize forward prediction intervals with configurable historical overlays that highlight uncertainty without cluttering the visualization.

---

## 2. Data Provenance & Academic Citations

Data is sourced from the **U.S. Census Bureau's Monthly Retail Trade Survey (MRTS)** and the **U.S. Bureau of Labor Statistics (BLS)** via the **Federal Reserve Bank of St. Louis (FRED)**:

| Retail Vertical / Series | FRED Series ID | Source Agency | NAICS Code | Units & Adjustment | Time Span |
|:---|:---:|:---:|:---:|:---:|:---:|
| **Health & Personal Care Stores** | `MRTSSM446USN` | U.S. Census Bureau | NAICS 446 | Millions of Dollars, NSA | 1992 Jan – 2026 Aug |
| **Clothing & Accessories Stores** | `MRTSSM448USN` | U.S. Census Bureau | NAICS 448 | Millions of Dollars, NSA | 1992 Jan – 2026 Aug |
| **Building Material & Supplies** | `MRTSSM444USN` | U.S. Census Bureau | NAICS 444 | Millions of Dollars, NSA | 1992 Jan – 2026 Aug |
| **Consumer Price Index (All Items)**| `CPIAUCNS` | U.S. Bureau of Labor Statistics | N/A | Index 1982–84=100, NSA | 1992 Jan – 2026 Aug |
| **Macro Retail Composite** | Constructed | Authors / Census Bureau | 444+446+448 | Millions of Dollars, NSA | 1992 Jan – 2026 Aug |

*Note: NSA = Not Seasonally Adjusted. All series maintain 100% continuous monthly observations without gaps.*

### Scholarly APA References:
- **Health & Personal Care:**  
  U.S. Census Bureau. (2026). *Retail Sales: Health and Personal Care Stores [MRTSSM446USN]*. Retrieved from FRED, Federal Reserve Bank of St. Louis: [https://fred.stlouisfed.org/series/MRTSSM446USN](https://fred.stlouisfed.org/series/MRTSSM446USN)
- **Clothing & Accessories:**  
  U.S. Census Bureau. (2026). *Retail Sales: Clothing and Clothing Accessories Stores [MRTSSM448USN]*. Retrieved from FRED, Federal Reserve Bank of St. Louis: [https://fred.stlouisfed.org/series/MRTSSM448USN](https://fred.stlouisfed.org/series/MRTSSM448USN)
- **Building Material & Garden Equipment:**  
  U.S. Census Bureau. (2026). *Retail Sales: Building Material and Garden Equipment and Supplies Dealers [MRTSSM444USN]*. Retrieved from FRED, Federal Reserve Bank of St. Louis: [https://fred.stlouisfed.org/series/MRTSSM444USN](https://fred.stlouisfed.org/series/MRTSSM444USN)
- **Consumer Price Index (CPI):**  
  U.S. Bureau of Labor Statistics. (2026). *Consumer Price Index for All Urban Consumers: All Items in U.S. City Average [CPIAUCNS]*. Retrieved from FRED, Federal Reserve Bank of St. Louis: [https://fred.stlouisfed.org/series/CPIAUCNS](https://fred.stlouisfed.org/series/CPIAUCNS)
- **Macro Retail Composite:**  
  Calculated directly as the aggregate volume across surveyed sectors:
  $$Y_{\text{macro}, t} = Y_{\text{health}, t} + Y_{\text{clothing}, t} + Y_{\text{building}, t}$$

---

## 3. Mathematical Formulations & Inflation Adjustment

### Inflation Adjustment (Real vs. Nominal Volume)
To control for monetary inflation and reveal real consumer purchasing volume over time, nominal monthly dollar sales are deflated using the chained Consumer Price Index:

$$\text{Sales}_{\text{real}, t} = \frac{\text{Sales}_{\text{nominal}, t}}{\text{CPI}_t / 100}$$

### Forecasting Model Class Formulations

1. **Time Series Linear Model (TSLM):**
   $$\text{Sales}_t = \beta_0 + \beta_1 t + \sum_{j=1}^{11} \gamma_j D_{j,t} + \varepsilon_t$$
   Estimates a deterministic linear trend slope with monthly seasonal indicator dummy regressors $D_{j,t}$ using Ordinary Least Squares (OLS).

2. **Exponential Smoothing State-Space Models (ETS):**
   Automated point and prediction interval generation using the Hyndman et al. (2008) framework. The model evaluates combinations of:
   - Error: Additive ($A$) or Multiplicative ($M$)
   - Trend: None ($N$), Additive ($A$), or Damped Additive ($Ad$)
   - Seasonality: None ($N$), Additive ($A$), or Multiplicative ($M$)
   Optimal architectures (e.g., $\text{ETS}(M,Ad,M)$ for building materials, $\text{ETS}(A,N,A)$ for clothing) are selected by minimizing the corrected Akaike Information Criterion ($\text{AICc}$).

3. **Seasonal Autoregressive Integrated Moving Average (ARIMA):**
   Multiplicative seasonal model $(p, d, q)(P, D, Q)_{12}$:
   $$\Phi(B^{12})\phi(B)(1 - B)^d (1 - B^{12})^D Y_t = c + \Theta(B^{12})\theta(B)\varepsilon_t$$
   Unit-root differencing orders ($d, D$) are determined via KPSS and seasonal strength tests, with AR and MA orders selected via stepwise AICc minimization.

4. **Equal-Weighted Ensemble Combo:**
   $$\hat{Y}_{\text{combo}, t+h} = \frac{\hat{Y}_{\text{TSLM}, t+h} + \hat{Y}_{\text{ETS}, t+h} + \hat{Y}_{\text{ARIMA}, t+h}}{3}$$
   Hedging across divergent model assumptions stabilizes out-of-sample forecast variance and reduces downside risk.

---

## 4. Evaluation Framework: Separating Validation from Forward Forecasting

The dashboard maintains a clear separation between **Model Validation (Backtesting)** and **Forward Forecasting (Decision Support)**:

- **Model & Accuracy Tab (Validation Backtesting):**  
  Evaluates out-of-sample predictive accuracy by holding out the final $K$ months (user-defined validation horizon: 6, 12, 18, 24, or 36 months). Models are trained on data prior to this window and tested against the held-out actual values using RMSE, MAE, MAPE, and MASE. Changing the validation window allows analysts to inspect how models perform over different economic regimes without altering future projection horizons.

- **Comparative Forecasts Tab (Forward Decision Projections):**  
  Produces forward-looking projections for business planning ($h$ months ahead into the future). In forward mode, models are trained on all available historical data up to August 2026, generating 80% and 95% prediction intervals. Recent actuals (configurable via history slider) are overlaid leading into the forecast origin to provide visual continuity without cluttering the visualization.
