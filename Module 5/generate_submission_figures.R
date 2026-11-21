suppressPackageStartupMessages({
  library(tidyverse)
  library(fpp3)
  library(scales)
  library(patchwork)
})

# 1. Load Data
df_raw <- read_csv("Module 5/data/retail_data_clean.csv", show_col_types = FALSE) %>%
  mutate(
    Month = yearmonth(Month),
    vertical_name = as.character(vertical_name)
  )

# Color palettes
sector_colors <- c(
  "Building & Garden Supplies" = "#1b9e77",
  "Clothing & Accessories" = "#d95f02",
  "Health & Personal Care" = "#7570b3"
)

# ------------------------------------------------------------------------------
# FIGURE 1: Exploration of Sectors and Aggregate LOESS
# ------------------------------------------------------------------------------
sub_sectors <- df_raw %>%
  filter(vertical_name %in% names(sector_colors))

p1_top <- ggplot(sub_sectors, aes(x = Month, y = sales_real, color = vertical_name)) +
  geom_line(linewidth = 0.8, show.legend = FALSE) +
  facet_wrap(~ vertical_name, scales = "free_y", ncol = 3) +
  scale_color_manual(values = sector_colors) +
  scale_y_continuous(labels = dollar_format(scale = 1, prefix = "$", suffix = "")) +
  scale_x_yearmonth(date_breaks = "6 years", date_labels = "%Y") +
  theme_minimal(base_size = 11.5) +
  theme(
    strip.text = element_text(face = "bold", size = 11.5, color = "#145A32"),
    strip.background = element_rect(fill = "#E8F8F5", color = "#A9DFBF", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(1.2, "lines"),
    axis.title = element_text(size = 10.5, face = "bold"),
    plot.title = element_text(face = "bold", size = 13, color = "#145A32", margin = margin(b = 4))
  ) +
  labs(
    title = "Historical Monthly Real Sales by Retail Sector (CPI-Deflated 1982-84 Volume, $M)",
    x = NULL,
    y = "Real Volume ($M)"
  )

agg_data <- df_raw %>%
  filter(vertical_name == "Macro Retail Total (Combined)")

p1_bot <- ggplot(agg_data, aes(x = Month, y = sales_real)) +
  geom_line(color = "#1F618D", linewidth = 0.75, alpha = 0.85) +
  geom_smooth(method = "loess", span = 0.25, color = "#C0392B", linewidth = 1.2, se = FALSE) +
  scale_y_continuous(labels = dollar_format(scale = 1, prefix = "$", suffix = "")) +
  scale_x_yearmonth(date_breaks = "4 years", date_labels = "%Y") +
  theme_minimal(base_size = 11.5) +
  theme(
    panel.grid.minor = element_blank(),
    axis.title = element_text(size = 10.5, face = "bold"),
    plot.title = element_text(face = "bold", size = 12.5, color = "#145A32", margin = margin(b = 3)),
    plot.subtitle = element_text(size = 10, color = "gray25")
  ) +
  labs(
    title = "Macro Retail Aggregate Total with Structural LOESS Trend (1992-2026)",
    subtitle = "Blue line tracks monthly combined volume; red curve shows structural macroeconomic trend",
    x = "Calendar Year",
    y = "Real Aggregate ($M)"
  )

fig1 <- p1_top / p1_bot + plot_layout(heights = c(1.3, 1.0))

ggsave(
  filename = "Module 5/figures/fig1_exploration.png",
  plot = fig1,
  width = 9.2,
  height = 4.4,
  dpi = 300,
  bg = "white"
)
cat("Figure 1 updated successfully.\n")

# ------------------------------------------------------------------------------
# FIGURE 2: 12-Month Out-of-Sample Backtest: TSLM Breakdown vs. ARIMA & ETS
# ------------------------------------------------------------------------------
data_all <- df_raw %>%
  mutate(Sales = as.numeric(sales_nominal)) %>%
  as_tsibble(index = Month, key = vertical_name)

val_months <- 12
trn <- data_all %>%
  group_by(vertical_name) %>%
  arrange(Month) %>%
  slice_head(n = -val_months) %>%
  ungroup() %>%
  as_tsibble(index = Month, key = vertical_name)

val <- data_all %>%
  group_by(vertical_name) %>%
  arrange(Month) %>%
  slice_tail(n = val_months) %>%
  ungroup() %>%
  as_tsibble(index = Month, key = vertical_name)

fits <- trn %>%
  model(
    TSLM = TSLM(Sales ~ trend() + season()),
    ETS = ETS(Sales),
    ARIMA = ARIMA(Sales)
  ) %>%
  mutate(Combo = (TSLM + ETS + ARIMA) / 3)

fc <- fits %>% forecast(h = val_months)

hist_display <- trn %>%
  group_by(vertical_name) %>%
  arrange(Month) %>%
  slice_tail(n = 24) %>%
  ungroup() %>%
  as_tsibble(index = Month, key = vertical_name)

model_order <- c("Actuals", "ARIMA", "ETS", "Combo", "TSLM (Rigid OLS)")
model_palette <- c(
  "Actuals" = "#111111",
  "ARIMA" = "#1E8449",
  "ETS" = "#2471A3",
  "Combo" = "#D35400",
  "TSLM (Rigid OLS)" = "#C0392B"
)
model_linetypes <- c(
  "Actuals" = "solid",
  "ARIMA" = "solid",
  "ETS" = "solid",
  "Combo" = "solid",
  "TSLM (Rigid OLS)" = "33"
)

fc_df <- as_tibble(fc) %>%
  transmute(
    vertical_name = as.character(vertical_name),
    Month = Month,
    Sales = .mean,
    Series_Model = if_else(.model == "TSLM", "TSLM (Rigid OLS)", as.character(.model))
  ) %>%
  mutate(
    Series_Model = factor(Series_Model, levels = model_order)
  )

actual_combined <- bind_rows(
  as_tibble(hist_display),
  as_tibble(val)
) %>%
  transmute(
    vertical_name = as.character(vertical_name),
    Month = Month,
    Sales = Sales,
    Series_Model = factor("Actuals", levels = model_order)
  )

combined_plot_data <- bind_rows(actual_combined, fc_df)

fig2 <- ggplot(combined_plot_data, aes(x = Month, y = Sales, color = Series_Model, linetype = Series_Model)) +
  geom_line(aes(linewidth = Series_Model)) +
  facet_wrap(~ vertical_name, scales = "free_y", ncol = 2) +
  scale_color_manual(values = model_palette, name = "Series / Model:") +
  scale_linetype_manual(values = model_linetypes, name = "Series / Model:") +
  scale_linewidth_manual(values = c(
    "Actuals" = 1.05,
    "ARIMA" = 0.88,
    "ETS" = 0.88,
    "Combo" = 0.88,
    "TSLM (Rigid OLS)" = 1.05
  ), name = "Series / Model:") +
  scale_y_continuous(labels = dollar_format(scale = 1, prefix = "$", suffix = "")) +
  scale_x_yearmonth(date_breaks = "1 year", date_labels = "%b %Y") +
  theme_minimal(base_size = 11.5) +
  theme(
    strip.text = element_text(face = "bold", size = 11.5, color = "#145A32"),
    strip.background = element_rect(fill = "#E8F8F5", color = "#A9DFBF", linewidth = 0.5),
    legend.position = "bottom",
    legend.title = element_text(face = "bold", size = 11, color = "#145A32"),
    legend.text = element_text(size = 10.5, face = "bold"),
    legend.key.width = unit(2.2, "lines"),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(1.2, "lines"),
    axis.title = element_text(size = 10.5, face = "bold"),
    plot.title = element_text(face = "bold", size = 13, color = "#145A32", margin = margin(b = 3)),
    plot.subtitle = element_text(size = 10, color = "gray25", margin = margin(b = 8))
  ) +
  labs(
    title = "12-Month Out-of-Sample Backtest: Linear Regression (TSLM) Breakdown vs. Dynamic Models",
    subtitle = "TSLM (red dashed) severely misjudges holiday peaks and post-shock levels; ARIMA and ETS dynamically track turning points",
    x = "Observation Month (2 Years Historical Actuals + 12-Month Held-Out Validation Period)",
    y = "Nominal Sales ($M)"
  )

ggsave(
  filename = "Module 5/figures/fig2_forecasts.png",
  plot = fig2,
  width = 9.2,
  height = 4.8,
  dpi = 300,
  bg = "white"
)
cat("Figure 2 updated successfully.\n")
