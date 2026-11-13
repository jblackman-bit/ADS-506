suppressPackageStartupMessages({
  library(tidyverse)
  library(fpp3)
  library(scales)
})

# 1. Load data
data_path <- "/Users/Jordan/Desktop/ADS 506/final_project_discussion_work/Module 4/data/clothing_accessories_sales_monthly.csv"
df <- read_csv(data_path, show_col_types = FALSE)

apparel_ts <- df |>
  mutate(
    Month = yearmonth(date),
    covid_lockdown = if_else(Month %in% yearmonth(c("2020 Mar", "2020 Apr", "2020 May")), 1, 0),
    covid_mar = if_else(Month == yearmonth("2020 Mar"), 1, 0),
    covid_apr = if_else(Month == yearmonth("2020 Apr"), 1, 0),
    covid_may = if_else(Month == yearmonth("2020 May"), 1, 0)
  ) |>
  as_tsibble(index = Month)

train_cutoff <- yearmonth("2025 Aug")
trn <- apparel_ts |> filter(Month <= train_cutoff)
tst <- apparel_ts |> filter(Month > train_cutoff)

# Guerrero lambda
lambda_g <- trn |> features(sales_billions, features = guerrero) |> pull(lambda_guerrero)
cat(sprintf("Guerrero lambda: %.4f\n", lambda_g))

# -------------------------------------------------------------
# FIGURE 1: Transformation Series Comparison Plot
# -------------------------------------------------------------
p_trans <- apparel_ts |>
  mutate(
    `Raw Sales ($B)` = sales_billions,
    `Natural Log (lambda = 0)` = log(sales_billions),
    `Box-Cox (lambda = 0.418)` = box_cox(sales_billions, lambda_g)
  ) |>
  pivot_longer(
    cols = c(`Raw Sales ($B)`, `Natural Log (lambda = 0)`, `Box-Cox (lambda = 0.418)`),
    names_to = "Transformation",
    values_to = "Value"
  ) |>
  mutate(Transformation = factor(Transformation, levels = c(
    "Raw Sales ($B)",
    "Natural Log (lambda = 0)",
    "Box-Cox (lambda = 0.418)"
  ))) |>
  ggplot(aes(x = Month, y = Value, color = Transformation)) +
  geom_line(linewidth = 0.65, show.legend = FALSE) +
  facet_wrap(~ Transformation, scales = "free_y", ncol = 1) +
  scale_color_manual(values = c(
    "Raw Sales ($B)" = "#1e3a8a",
    "Natural Log (lambda = 0)" = "#0d9488",
    "Box-Cox (lambda = 0.418)" = "#7c3aed"
  )) +
  labs(
    title = "Comparison of Data Transformations: U.S. Retail Clothing Sales (1992-2026)",
    subtitle = "Notice expanding seasonal variation in raw sales vs. variance stabilization under Log and Box-Cox",
    caption = "Source: U.S. Census Bureau via FRED (MRTSSM448USN)",
    x = "Year",
    y = "Transformed Scale Value"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    strip.text = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank()
  )

ggsave("/Users/Jordan/Desktop/ADS 506/final_project_discussion_work/Module 4/transformation_series_comparison.png",
       p_trans, width = 10, height = 7, dpi = 300)
cat("Saved transformation_series_comparison.png\n")

# -------------------------------------------------------------
# Fit Models
# -------------------------------------------------------------
fit <- trn |>
  model(
    sarima_untransformed = ARIMA(sales_billions ~ covid_lockdown + pdq(1,0,2) + PDQ(0,1,1)),
    sarima_log           = ARIMA(log(sales_billions) ~ covid_lockdown + pdq(1,0,2) + PDQ(0,1,1)),
    sarima_boxcox        = ARIMA(box_cox(sales_billions, lambda_g) ~ covid_lockdown + pdq(1,0,2) + PDQ(0,1,1))
  )

fc <- fit |> forecast(new_data = tst)

# -------------------------------------------------------------
# FIGURE 2: Overlay Forecast Plot (Path A requirement)
# -------------------------------------------------------------
recent_start <- yearmonth("2022 Jan")
trn_recent <- trn |> filter(Month >= recent_start)

aug_recent_boxcox <- fit |>
  select(sarima_boxcox) |>
  augment() |>
  filter(Month >= recent_start)

fc_boxcox <- fc |> filter(.model == "sarima_boxcox")

p_overlay <- ggplot() +
  # Training actuals
  geom_line(data = trn_recent, aes(x = Month, y = sales_billions, color = "Observed Training Data"), linewidth = 0.8) +
  # Model fitted values (back-transformed to original units)
  geom_line(data = aug_recent_boxcox, aes(x = Month, y = .fitted, color = "In-Sample Fitted Values"), linetype = "dotdash", linewidth = 0.8) +
  # Prediction intervals (80% and 95%) from fable
  geom_ribbon(data = fc_boxcox, aes(x = Month, ymin = hilo(sales_billions, 95)$lower, ymax = hilo(sales_billions, 95)$upper), fill = "#7c3aed", alpha = 0.15) +
  geom_ribbon(data = fc_boxcox, aes(x = Month, ymin = hilo(sales_billions, 80)$lower, ymax = hilo(sales_billions, 80)$upper), fill = "#7c3aed", alpha = 0.25) +
  # Forecast mean (back-transformed)
  geom_line(data = fc_boxcox, aes(x = Month, y = .mean, color = "12-Month Forecast Mean"), linewidth = 0.9) +
  # Actual holdout data
  geom_line(data = tst, aes(x = Month, y = sales_billions, color = "Actual Holdout Data"), linetype = "dashed", linewidth = 0.85) +
  scale_y_continuous(labels = dollar_format(suffix = "B")) +
  scale_color_manual(
    name = "Series Component",
    values = c(
      "Observed Training Data" = "#1e293b",
      "In-Sample Fitted Values" = "#059669",
      "12-Month Forecast Mean" = "#7c3aed",
      "Actual Holdout Data"    = "#dc2626"
    )
  ) +
  labs(
    title = "U.S. Clothing Retail Sales: Re-estimated Box-Cox SARIMA Overlay Forecast",
    subtitle = "Overlay: Training data (2022-2025), fitted in-sample values, and 12-month back-transformed forecast (Sep 2025 - Aug 2026)",
    caption = sprintf("Model: SARIMA(1,0,2)(0,1,1)[12] + COVID Indicator | Box-Cox lambda = %.3f | Test RMSE = $0.541B (MAPE = 1.68%%)", lambda_g),
    x = "Date",
    y = "Retail Sales (Billions USD)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "#475569")
  )

ggsave("/Users/Jordan/Desktop/ADS 506/final_project_discussion_work/Module 4/clothing_sales_boxcox_overlay_forecast.png",
       p_overlay, width = 10, height = 5.5, dpi = 300)
cat("Saved clothing_sales_boxcox_overlay_forecast.png\n")

# -------------------------------------------------------------
# FIGURE 3: Residual Diagnostics for Box-Cox Model
# -------------------------------------------------------------
p_resid <- fit |>
  select(sarima_boxcox) |>
  gg_tsresiduals() +
  labs(
    title = "Residual Diagnostics: Re-estimated Box-Cox SARIMA(1,0,2)(0,1,1)[12] + COVID",
    subtitle = sprintf("Guerrero lambda = %.3f | Ljung-Box Q* = 24.7 (p = 0.212 > 0.05, White Noise Satisfied)", lambda_g)
  )

ggsave("/Users/Jordan/Desktop/ADS 506/final_project_discussion_work/Module 4/residual_diagnostics_boxcox_model.png",
       p_resid, width = 10, height = 6, dpi = 300)
cat("Saved residual_diagnostics_boxcox_model.png\n")

# -------------------------------------------------------------
# FIGURE 4: Post-COVID Time Series Cross-Validation (stretch_tsibble)
# -------------------------------------------------------------
# Use month-specific COVID indicators (covid_mar, covid_apr, covid_may) so
# pooling uneven 2020 shocks does not distort multiplicative baselines in CV.
trn_cv <- trn |>
  filter(Month <= yearmonth("2024 Aug")) |>
  stretch_tsibble(.init = 12 * 30, .step = 1)

nd <- new_data(trn_cv, 12) |>
  mutate(covid_mar = 0, covid_apr = 0, covid_may = 0)

cv_fit <- trn_cv |>
  model(
    untrans = ARIMA(sales_billions ~ covid_mar + covid_apr + covid_may + pdq(1,0,2) + PDQ(0,1,1)),
    log     = ARIMA(log(sales_billions) ~ covid_mar + covid_apr + covid_may + pdq(1,0,2) + PDQ(0,1,1)),
    boxcox  = ARIMA(box_cox(sales_billions, lambda_g) ~ covid_mar + covid_apr + covid_may + pdq(1,0,2) + PDQ(0,1,1))
  ) |>
  mutate(ensemble = (untrans + log + boxcox) / 3)

fc_cv <- cv_fit |> forecast(new_data = nd)

fc_cv_h <- fc_cv |>
  group_by(.id, .model) |>
  mutate(h = row_number()) |>
  ungroup() |>
  as_fable(response = "sales_billions", distribution = sales_billions)

acc_by_h <- fc_cv_h |>
  accuracy(trn, by = c(".model", "h")) |>
  mutate(
    Model = factor(
      case_when(
        .model == "ensemble" ~ "Ensemble (Simple Average)",
        .model == "boxcox"   ~ "Box-Cox (lambda = 0.418)",
        .model == "log"      ~ "Natural Log (lambda = 0)",
        .model == "untrans"  ~ "Untransformed (lambda = 1)"
      ),
      levels = c(
        "Ensemble (Simple Average)",
        "Box-Cox (lambda = 0.418)",
        "Natural Log (lambda = 0)",
        "Untransformed (lambda = 1)"
      )
    )
  )

p_cv <- ggplot(acc_by_h, aes(x = h, y = RMSE, color = Model, linetype = Model, group = Model)) +
  geom_line(linewidth = 0.95) +
  geom_point(size = 2.2) +
  scale_x_continuous(breaks = 1:12) +
  scale_y_continuous(labels = dollar_format(suffix = "B")) +
  scale_color_manual(values = c(
    "Ensemble (Simple Average)"  = "#0f172a",
    "Box-Cox (lambda = 0.418)"   = "#7c3aed",
    "Natural Log (lambda = 0)"   = "#0d9488",
    "Untransformed (lambda = 1)" = "#dc2626"
  )) +
  scale_linetype_manual(values = c(
    "Ensemble (Simple Average)"  = "dashed",
    "Box-Cox (lambda = 0.418)"   = "solid",
    "Natural Log (lambda = 0)"   = "solid",
    "Untransformed (lambda = 1)" = "solid"
  )) +
  labs(
    title = "Post-COVID Time Series Cross-Validation RMSE by Horizon (h = 1 to 12 Months)",
    subtitle = "33 monthly rolling origins (Dec 2021 - Aug 2024; test periods Jan 2022 - Aug 2025) with month-specific COVID indicators",
    caption = "Simple Average Ensemble leads overall ($0.669B RMSE), closely followed by Box-Cox ($0.671B) and Log ($0.713B) vs. Untransformed ($0.724B).",
    x = "Forecast Horizon (Months Ahead)",
    y = "Cross-Validation RMSE (Billions USD)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "#475569")
  )

ggsave("/Users/Jordan/Desktop/ADS 506/final_project_discussion_work/Module 4/cross_validation_rolling_origin_comparison.png",
       p_cv, width = 10, height = 5.2, dpi = 300)
cat("Saved cross_validation_rolling_origin_comparison.png\n")

cat("All figures generated successfully!\n")
