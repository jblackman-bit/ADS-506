# ==============================================================================
# ADS 506: Applied Time Series Analysis - Module 1 Discussion
# Script: top_5_states_building_permits.R
# Author: Jordan Blackman
# Purpose: Ingest, process, and visualize monthly building permits for the 
#          top 5 states all-time (TX, FL, CA, NC, GA) using tidyverts (fpp3).
# ==============================================================================

# 1. Load Libraries ------------------------------------------------------------
library(tidyverse)
library(fpp3)

# 2. Define Top 5 States & FRED Series Codes ------------------------------------
# Top 5 states identified by all-time cumulative monthly building permits (1988-present):
# 1. Texas (TX)
# 2. Florida (FL)
# 3. California (CA)
# 4. North Carolina (NC)
# 5. Georgia (GA)

top_states <- c(
  "Texas"          = "TXBPPRIV",
  "Florida"        = "FLBPPRIV",
  "California"     = "CABPPRIV",
  "North Carolina" = "NCBPPRIV",
  "Georgia"        = "GABPPRIV"
)

# 3. Fetch Data from FRED ------------------------------------------------------
data_dir <- "data"
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

state_data_list <- list()

for (st_name in names(top_states)) {
  ticker <- top_states[[st_name]]
  url <- sprintf("https://fred.stlouisfed.org/graph/fredgraph.csv?id=%s", ticker)
  dest_file <- file.path(data_dir, paste0(ticker, ".csv"))
  
  # Download if not already cached
  if (!file.exists(dest_file)) {
    message(paste("Downloading data for:", st_name, paste0("(", ticker, ")")))
    download.file(url, dest_file, quiet = TRUE)
  }
  
  raw_df <- read_csv(dest_file, show_col_types = FALSE)
  names(raw_df) <- c("date", "permits")
  
  state_data_list[[st_name]] <- raw_df |>
    mutate(
      state = st_name,
      permits = as.numeric(permits)
    ) |>
    filter(!is.na(permits))
}

# 4. Construct Tidy tsibble ----------------------------------------------------
permits_top5_ts <- bind_rows(state_data_list) |>
  mutate(Month = yearmonth(date)) |>
  select(Month, state, permits) |>
  as_tsibble(index = Month, key = state)

# Export clean CSV
write_csv(permits_top5_ts, "top_5_states_permits_monthly.csv")

# 5. Create Time Series Plots --------------------------------------------------

# Plot A: Comparative Multi-Line Time Series Plot (Discussion Post Visual)
p_comparison <- ggplot(permits_top5_ts, aes(x = Month, y = permits, color = state)) +
  geom_line(linewidth = 0.7, alpha = 0.85) +
  scale_y_continuous(labels = scales::comma) +
  scale_color_brewer(palette = "Set1") +
  labs(
    title = "Top 5 U.S. States by New Housing Permits Authorized (Monthly, 1988–Present)",
    subtitle = "U.S. Census Bureau Building Permits Survey (Not Seasonally Adjusted)",
    caption = "Source: Federal Reserve Bank of St. Louis (FRED) | Analysis by Jordan Blackman",
    x = "Year",
    y = "Total Housing Units Authorized (Monthly)",
    color = "State"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "gray30", margin = margin(b = 10)),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Plot B: Faceted View with STL Trend Smoother for Component Inspection
p_faceted <- ggplot(permits_top5_ts, aes(x = Month, y = permits, color = state)) +
  geom_line(alpha = 0.4, linewidth = 0.5) +
  geom_smooth(method = "loess", span = 0.05, se = FALSE, color = "black", linewidth = 0.8) +
  facet_wrap(~ state, scales = "free_y", ncol = 1) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Monthly Housing Permit Trajectories & Trend-Cycle (Loess Overlay)",
    subtitle = "Comparing Sunbelt growth against historic macroeconomic shocks (2008 GFC, 2020 COVID)",
    x = "Year",
    y = "Authorized Units",
    caption = "Black line represents smoothed trend-cycle"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold")
  )

# Plot C: STL Decomposition of #1 State (Texas) connecting with Module 1
p_stl_texas <- permits_top5_ts |>
  filter(state == "Texas") |>
  model(stl = STL(permits)) |>
  components() |>
  autoplot() +
  labs(
    title = "STL Decomposition: Texas Monthly Housing Permits",
    subtitle = "Components: Level, Upward Trend, Annual Seasonality (s = 12), and Noise"
  ) +
  theme_minimal()

# 6. Save Outputs --------------------------------------------------------------
ggsave("top_5_states_building_permits.png", p_comparison, width = 10, height = 6, dpi = 300)
ggsave("top_5_states_faceted_trends.png", p_faceted, width = 9, height = 11, dpi = 300)
ggsave("texas_stl_decomposition.png", p_stl_texas, width = 9, height = 7, dpi = 300)

message("Plots and data successfully generated in Discussion folder!")
