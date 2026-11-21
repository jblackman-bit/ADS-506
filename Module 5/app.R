# ==============================================================================
# ADS 506 - Applied Time Series Analysis | Module 5 Assignment
# Interactive Shiny Web Application: U.S. Retail Sales Forecasting & Storytelling
# Author: Jordan Blackman
# Date: November 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Package Dependencies & Data Ingestion
# ------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(tidyverse)
  library(fpp3)
  library(urca)
  library(gt)
  library(scales)
  library(patchwork)
  library(markdown)
  library(DT)
})

# Clean relative path lookup for retail_data_clean.csv
candidate_paths <- c(
  "data/retail_data_clean.csv",
  "Module 5/data/retail_data_clean.csv",
  file.path("..", "data", "retail_data_clean.csv"),
  file.path("..", "Module 5", "data", "retail_data_clean.csv")
)
data_path <- candidate_paths[file.exists(candidate_paths)][1]
if (is.na(data_path)) {
  stop("FATAL: retail_data_clean.csv could not be located in any expected directory.")
}

candidate_about <- c(
  "about.md",
  "Module 5/about.md",
  file.path("..", "about.md"),
  file.path("..", "Module 5", "about.md")
)
about_path <- candidate_about[file.exists(candidate_about)][1]

raw_retail <- read_csv(
  data_path,
  show_col_types = FALSE
) %>%
  mutate(
    Month = yearmonth(Month),
    vertical_name = as.character(vertical_name)
  )

vertical_choices <- c(
  "Building & Garden Supplies",
  "Clothing & Accessories",
  "Health & Personal Care",
  "Macro Retail Total (Combined)"
)

available_years <- sort(unique(year(raw_retail$Month)))
min_year <- min(available_years)
max_year <- max(available_years)

month_abbr <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
month_numbers <- setNames(1:12, month_abbr)

# ------------------------------------------------------------------------------
# 2. UI Layout
# ------------------------------------------------------------------------------

ui <- fluidPage(
  withMathJax(),
  
  # Inject MathJax and Custom Green Brand Styling
  tags$head(
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS_CHTML"),
    tags$script(HTML("
      MathJax.Hub.Config({
        tex2jax: {
          inlineMath: [['$','$'], ['\\\\(','\\\\)']],
          displayMath: [['$$','$$'], ['\\\\[','\\\\]']],
          processEscapes: true
        }
      });
      $(document).on('shown.bs.tab', 'a[data-toggle=\"tab\"]', function(e) {
        if (window.MathJax) {
          MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
        }
      });
    ")),
    tags$style(HTML("
      /* Top Navigation Bar: Green brand styling with white text */
      .nav-tabs {
        border-bottom: 2px solid #1E8449 !important;
        margin-bottom: 20px;
      }
      .nav-tabs > li > a {
        background-color: #E8F8F5 !important;
        color: #145A32 !important;
        font-weight: 600 !important;
        border: 1px solid #A9DFBF !important;
        border-bottom: none !important;
        margin-right: 6px !important;
        border-radius: 6px 6px 0 0 !important;
        padding: 10px 18px !important;
        transition: all 0.2s ease-in-out;
      }
      .nav-tabs > li > a:hover {
        background-color: #D4EFDF !important;
        color: #0E6251 !important;
      }
      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:focus,
      .nav-tabs > li.active > a:hover {
        background-color: #1E8449 !important;
        color: #FFFFFF !important;
        border: 1px solid #1E8449 !important;
        border-bottom: 2px solid #1E8449 !important;
      }
      
      /* Control Panels: Matching Green Headers */
      .green-panel {
        background-color: #F9FCF9 !important;
        border: 1px solid #A9DFBF !important;
        border-radius: 8px !important;
        padding: 16px !important;
        box-shadow: 0 2px 6px rgba(0,0,0,0.04) !important;
      }
      .green-panel-header {
        background-color: #1E8449;
        color: #FFFFFF;
        padding: 10px 14px;
        margin: -16px -16px 14px -16px;
        border-radius: 7px 7px 0 0;
      }
      .green-panel-header h4 {
        margin: 0;
        font-size: 1.05rem;
        font-weight: 700;
        color: #FFFFFF;
      }
      .green-panel-header p {
        margin: 2px 0 0 0;
        font-size: 0.8rem;
        color: #E8F8F5;
      }
      
      /* Clean Collapsible Details */
      details.clean-details {
        border: 1px solid #D5DBDB;
        border-radius: 6px;
        background-color: #FAFAFA;
        margin-bottom: 12px;
      }
      details.clean-details summary {
        padding: 8px 12px;
        font-weight: 600;
        color: #1E8449;
        cursor: pointer;
        list-style: none;
      }
      details.clean-details summary::-webkit-details-marker {
        display: none;
      }
      details.clean-details[open] {
        border-color: #A9DFBF;
        background-color: #FFFFFF;
      }
      details.clean-details .details-content {
        padding: 10px 14px;
        border-top: 1px solid #EAEDED;
        font-size: 0.85rem;
        color: #4A5568;
      }
      
      /* Inline info icon for tooltips */
      .info-tip {
        color: #1E8449;
        cursor: pointer;
        font-size: 0.85rem;
        margin-left: 5px;
      }
      
      /* Scorecard Equal Height */
      .scorecard-box {
        height: 115px;
        display: flex;
        flex-direction: column;
        justify-content: center;
      }
      
      /* Subtle table styling */
      .gt_table {
        border-radius: 6px;
        overflow: hidden;
      }
    "))
  ),
  
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#1E8449",
    success = "#27AE60",
    base_font = font_google("Open Sans"),
    heading_font = font_google("Montserrat")
  ),
  
  titlePanel(
    div(
      h2("U.S. Retail Sales: Time Series Exploration & Forecasting", style = "font-weight: 700; margin-bottom: 2px; color: #145A32;"),
      p(
        "Interactive Forecasting and Model Evaluation Dashboard | ",
        strong("Jordan Blackman", style = "color: #1E8449; font-weight: 700;"),
        " | ADS 506 Module 5", 
        style = "color: #555; font-size: 1.05rem; margin-top: 0px;"
      )
    ),
    windowTitle = "U.S. Retail Sales Forecasting Dashboard - Jordan Blackman"
  ),
  
  tabsetPanel(
    id = "main_tabs",
    
    # --------------------------------------------------------------------------
    # TAB 1: Visualize & Explore
    # --------------------------------------------------------------------------
    tabPanel(
      "Visualize & Explore",
      icon = icon("chart-line"),
      br(),
      fluidRow(
        column(
          width = 4,
          div(
            class = "well green-panel",
            div(
              class = "green-panel-header",
              h4(icon("sliders-h"), " Data & Display Controls"),
              p("Filter retail sectors, currency basis, and historical observation window.")
            ),
            
            selectInput(
              "selected_verticals",
              "Select Retail Verticals:",
              choices = vertical_choices,
              selected = vertical_choices,
              multiple = TRUE
            ),
            
            radioButtons(
              "sales_measure",
              span(
                "Sales Valuation Basis:",
                tooltip(
                  icon("info-circle", class = "info-tip"),
                  "Nominal reflects unadjusted cash flows in current dollars ($M); Real deflates by CPI to isolate true physical purchasing volume."
                )
              ),
              choices = c(
                "Nominal Sales (Current Dollars, $M)" = "sales_nominal",
                "Real Sales (CPI-Adjusted Volume, $M)" = "sales_real"
              ),
              selected = "sales_nominal"
            ),
            
            hr(),
            h5("Historical Study Window (Exploration Zoom):", style = "font-weight: 600; color: #145A32;"),
            fluidRow(
              column(6, selectInput("start_year", "Start Year:", choices = available_years, selected = 1992)),
              column(6, selectInput("start_month", "Start Month:", choices = month_numbers, selected = 1))
            ),
            fluidRow(
              column(6, selectInput("end_year", "End Year:", choices = available_years, selected = max_year)),
              column(6, selectInput("end_month", "End Month:", choices = month_numbers, selected = 8))
            ),
            
            hr(),
            h5("Visualization Options:", style = "font-weight: 600; color: #145A32;"),
            radioButtons(
              "viz_mode",
              "Plot Display View:",
              choices = c(
                "Time Series & Aggregate Total" = "ts_total",
                "STL Decomposition (Trend / Season)" = "stl",
                "Monthly Seasonality Subseries" = "season"
              ),
              selected = "ts_total"
            ),
            checkboxInput(
              "free_y_scales", 
              span(
                "Free Y-axis scales across verticals",
                tooltip(
                  icon("info-circle", class = "info-tip"),
                  "Free Y-axis scales setting only applies to the faceted Time Series view and Aggregate Totals."
                )
              ), 
              value = TRUE
            ),
            
            tags$details(
              class = "clean-details",
              style = "margin-top: 15px;",
              tags$summary(
                tags$span(icon("database"), style = "margin-right: 5px; color: #1E8449;"),
                tags$span("Data Provenance & Citations", style = "font-size: 0.82rem; font-weight: 600;")
              ),
              div(
                class = "details-content",
                strong("Data Sources: "), "U.S. Census Bureau (MRTS NAICS 444, 446, 448) & U.S. BLS (CPIAUCNS) via FRED. ",
                "All sales figures are measured in Millions of Dollars ($M)."
              )
            )
          )
        ),
        
        column(
          width = 8,
          uiOutput("viz_summary_cards"),
          plotOutput("exploration_plot", height = "760px")
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 2: Model Specifications & Accuracy (Validation Backtesting)
    # --------------------------------------------------------------------------
    tabPanel(
      "Model & Accuracy",
      icon = icon("table"),
      br(),
      fluidRow(
        column(
          width = 12,
          div(
            class = "alert alert-success",
            style = "background-color: #EAFAF1; border-color: #A9DFBF; color: #145A32;",
            h5(icon("dollar-sign"), " Model Validation & Goodness-of-Fit Diagnostics (Nominal Sales Basis)", style = "font-weight: bold; margin-bottom: 4px;"),
            p("Historical backtesting diagnostics across all four retail series. ",
              strong("Evaluated exclusively on Nominal Retail Sales (Current Dollars in Millions - $M)"), 
              " to reflect actual commercial cash flows. Error metrics (RMSE, MAE) are in Nominal $M; MAPE is in %.", 
              style = "margin-bottom: 0px;")
          ),
          
          div(
            class = "well green-panel",
            div(
              class = "green-panel-header",
              h4(icon("cogs"), " Model Validation Settings"),
              p("Configure backtest evaluation split and metric sorting (all models evaluated on nominal sales).")
            ),
            fluidRow(
              column(
                width = 4,
                sliderInput(
                  "val_horizon",
                  span(
                    "Validation Horizon (Months):",
                    tooltip(icon("info-circle", class = "info-tip"), "Held-out period used strictly for scoring out-of-sample forecast accuracy.")
                  ),
                  min = 6,
                  max = 36,
                  value = 12,
                  step = 6
                )
              ),
              column(
                width = 4,
                selectInput(
                  "metric_choice",
                  span(
                    "Highlighting Metric:",
                    tooltip(icon("info-circle", class = "info-tip"), "Evaluation metric highlighted in the accuracy table (RMSE/MAE in Nominal $M, MAPE in %).")
                  ),
                  choices = c("RMSE", "MAE", "MAPE", "MASE"),
                  selected = "RMSE"
                )
              ),
              column(
                width = 4,
                selectInput(
                  "sort_vertical",
                  span(
                    "Sort Models by Vertical:",
                    tooltip(icon("info-circle", class = "info-tip"), "Sorts table rows in ascending order of out-of-sample validation error for the chosen vertical.")
                  ),
                  choices = vertical_choices,
                  selected = "Building & Garden Supplies"
                )
              )
            ),
            tags$details(
              class = "clean-details",
              style = "margin-top: 5px; margin-bottom: 0px;",
              tags$summary(
                tags$span(icon("filter"), style = "margin-right: 5px; color: #1E8449;"),
                tags$span("Filter Series Displayed in Backtest Plot & Table", style = "font-size: 0.85rem; font-weight: 600;")
              ),
              div(
                class = "details-content",
                checkboxGroupInput(
                  "val_series_to_plot",
                  NULL,
                  choices = vertical_choices,
                  selected = vertical_choices,
                  inline = TRUE
                )
              )
            )
          ),
          
          # Date Range Banner
          uiOutput("modeling_window_banner"),
          br(),
          
          # Section 1: Model Specifications (Collapsible <details>, Default Collapsed)
          tags$details(
            tags$summary(
              tags$span(icon("chevron-right"), style = "margin-right: 5px; color: #1E8449;"),
              tags$strong("1. Model Specifications & Orders (Click to Expand)", style = "color: #145A32; font-size: 1.05rem; cursor: pointer;"),
              tags$span(" — Auto-specified mathematical forms for TSLM, ETS state-space, and Seasonal ARIMA across all series", style = "color: #666; font-size: 0.88rem;"),
              style = "cursor: pointer; padding: 10px 14px; background-color: #EAFAF1; border-radius: 6px; border: 1px solid #A9DFBF; margin-bottom: 15px;"
            ),
            div(
              style = "margin-top: 10px; margin-bottom: 20px;",
              htmlOutput("model_specs_table")
            )
          ),
          
          # Section 2: Combined In-Sample and Out-of-Sample Accuracy Table (Always On)
          h4(
            "2. Combined Model Accuracy: Out-of-Sample Validation (In-Sample Training) ",
            tooltip(
              icon("info-circle", class = "info-tip", style = "font-size: 0.95rem;"),
              "Formatted as: Out-of-Sample Validation Error (In-Sample Training Error in Parentheses). Color-coded by out-of-sample error (Green = best fit, Red = highest error). Evaluated exclusively in Nominal $M."
            ),
            style = "font-weight: 700; color: #145A32;"
          ),
          htmlOutput("combined_accuracy_table"),
          br(),
          
          # Section 3: Validation Backtest Plots - Each on its own row and larger (Always On)
          h4(
            "3. Validation Backtest: Forecast vs. Actuals (One Row Per Vertical) ",
            tooltip(
              icon("info-circle", class = "info-tip", style = "font-size: 0.95rem;"),
              "Each vertical is rendered on its own full-width row. Black line shows actual sales observations ($M); colored lines show out-of-sample model predictions on Nominal Sales."
            ),
            style = "font-weight: 700; color: #145A32;"
          ),
          plotOutput("validation_backtest_plot", height = "850px"),
          br(),
          
          # Section 4: Diagnostic Insights Takeaway Card (Expandable to reduce noise)
          tags$details(
            class = "clean-details",
            style = "margin-top: 15px; margin-bottom: 25px;",
            tags$summary(
              tags$span(icon("lightbulb"), style = "margin-right: 6px; color: #1E8449;"),
              tags$strong("Diagnostic Insights & Model Selection Takeaway (Click to Expand)", style = "color: #145A32; font-size: 1rem; cursor: pointer;")
            ),
            div(
              class = "details-content",
              style = "font-size: 0.92rem; line-height: 1.6;",
              uiOutput("model_insights_text")
            )
          )
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 3: Comparative Forecasts (Forward Projections & Scenarios)
    # --------------------------------------------------------------------------
    tabPanel(
      "Comparative Forecasts",
      icon = icon("chart-area"),
      br(),
      fluidRow(
        column(
          width = 3,
          div(
            class = "well green-panel",
            div(
              class = "green-panel-header",
              h4(icon("chart-line"), " Forecast Parameters"),
              p("Operational projections evaluated exclusively in Nominal Dollars ($M).")
            ),
            
            radioButtons(
              "fc_mode",
              "Forecasting Mode:",
              choices = c(
                "Forward Planning (Into Future 2026–2027+)" = "future",
                "Validation Backtest (Overlaid vs Actuals)" = "backtest"
              ),
              selected = "future"
            ),
            
            sliderInput(
              "fc_horizon",
              "Forecast Horizon (Months Ahead):",
              min = 6,
              max = 36,
              value = 12,
              step = 6
            ),
            
            checkboxGroupInput(
              "ci_levels",
              span(
                "Prediction Interval Confidence:",
                tooltip(
                  icon("info-circle", class = "info-tip"),
                  "Confidence intervals are displayed in Faceted Grid layout; Overlay layout displays comparative mean forecast paths."
                )
              ),
              choices = c("80%" = 80, "95%" = 95),
              selected = c(80, 95),
              inline = TRUE
            ),
            
            sliderInput(
              "years_display",
              span(
                "Years of Historical Actuals to Display:",
                tooltip(
                  icon("info-circle", class = "info-tip"),
                  "Trimming displayed history ensures forecast paths and actual overlays remain clear and legible."
                )
              ),
              min = 1,
              max = 10,
              value = 2,
              step = 1
            ),
            
            hr(),
            checkboxGroupInput(
              "fc_series_to_plot",
              "Retail Verticals to Include in Forecast:",
              choices = vertical_choices,
              selected = vertical_choices,
              inline = FALSE
            ),
            
            hr(),
            checkboxGroupInput(
              "models_to_plot",
              "Models to Include in Forecast:",
              choices = c("TSLM", "ETS", "ARIMA", "Combo"),
              selected = c("TSLM", "ETS", "ARIMA", "Combo"),
              inline = FALSE
            ),
            
            radioButtons(
              "fc_layout",
              "Forecast Plot Layout:",
              choices = c(
                "Overlay Comparison by Vertical (One Row Per Vertical)" = "overlay",
                "Faceted Grid (Model x Vertical)" = "grid"
              ),
              selected = "overlay"
            ),
            
            tags$details(
              class = "clean-details",
              style = "margin-top: 15px;",
              tags$summary(
                tags$span(icon("info-circle"), style = "color: #1E8449; margin-right: 5px;"),
                tags$span("Forecasting Notes & Caveats", style = "font-size: 0.82rem; font-weight: 600;")
              ),
              div(
                class = "details-content",
                p(strong("Nominal Sales: "), "All forecasts and backtests are evaluated in Nominal Millions of Dollars ($M) to project unadjusted cash flows."),
                p(strong("Intervals: "), "80% and 95% confidence bands are rendered in Faceted Grid mode. Overlay mode displays multi-model mean trajectories on separate vertical rows.")
              )
            )
          )
        ),
        
        column(
          width = 9,
          uiOutput("fc_mode_banner"),
          plotOutput("forecast_plot", height = "850px"),
          br(),
          div(
            style = "display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 8px; flex-wrap: wrap; gap: 8px;",
            div(
              h5("Forecast Values & Prediction Intervals Table (Nominal Sales in Millions of Dollars - $M)", style = "font-weight: 700; color: #145A32; margin-bottom: 2px;"),
              p("Point forecasts and prediction bounds expressed in Nominal Millions of Dollars ($M). Cleanly formatted for executive review.", 
                style = "color: #666; font-size: 0.88rem; margin-bottom: 0px;")
            ),
            downloadButton("download_forecast_csv", "Download Forecasts (CSV)", class = "btn-success btn-sm", icon = icon("download"))
          ),
          DT::DTOutput("forecast_table")
        )
      )
    ),
    
    # --------------------------------------------------------------------------
    # TAB 4: About & Methodology
    # --------------------------------------------------------------------------
    tabPanel(
      "About & Guide",
      icon = icon("info-circle"),
      br(),
      fluidRow(
        column(
          width = 10,
          offset = 1,
          div(
            class = "card p-4 shadow-sm",
            if (file.exists(about_path)) {
              includeMarkdown(about_path)
            } else {
              p("About documentation file (about.md) could not be loaded.")
            }
          )
        )
      )
    )
  )
)

# ------------------------------------------------------------------------------
# 3. Server Logic
# ------------------------------------------------------------------------------

server <- function(input, output, session) {
  
  # Reactive Data Filtering based on user selections (for Tab 1 visualization)
  filtered_data <- reactive({
    req(
      input$selected_verticals,
      input$start_year,
      input$end_year,
      input$start_month,
      input$end_month,
      input$sales_measure
    )
    
    start_date <- yearmonth(paste(input$start_year, input$start_month, "01", sep = "-"))
    end_date <- yearmonth(paste(input$end_year, input$end_month, "01", sep = "-"))
    
    validate(
      need(length(input$selected_verticals) >= 1, "Please select at least one retail vertical."),
      need(start_date < end_date, "Start date must be chronologically earlier than End date.")
    )
    
    measure_col <- sym(input$sales_measure)
    
    raw_retail %>%
      filter(
        vertical_name %in% input$selected_verticals,
        Month >= start_date,
        Month <= end_date
      ) %>%
      mutate(Sales = as.numeric(!!measure_col)) %>%
      as_tsibble(index = Month, key = vertical_name)
  })
  
  # Aggregate total of selected verticals (excluding double-counting Macro Retail if present)
  total_data <- reactive({
    data <- filtered_data()
    req(nrow(data) > 0)
    
    sectors <- unique(data$vertical_name)
    sub_data <- if (length(sectors) > 1 && "Macro Retail Total (Combined)" %in% sectors) {
      data %>% filter(vertical_name != "Macro Retail Total (Combined)")
    } else {
      data
    }
    
    sub_data %>%
      as_tibble() %>%
      group_by(Month) %>%
      summarize(
        Sales = sum(Sales, na.rm = TRUE),
        vertical_name = "Selected Verticals Total",
        .groups = "drop"
      )
  })
  
  # Reactive Y-Axis Label for Tab 1
  y_axis_label_tab1 <- reactive({
    if (input$sales_measure == "sales_nominal") {
      "Nominal Sales (Millions of Current Dollars - $M)"
    } else {
      "Real Sales (Millions of 1982-84 Chained Dollars - $M)"
    }
  })
  
  # KPI Summary Cards in Tab 1 (Equal Height, Swapped for Total Cumulative Revenue in $M)
  output$viz_summary_cards <- renderUI({
    data <- filtered_data()
    req(nrow(data) > 0)
    
    sectors <- unique(data$vertical_name)
    sub_data <- if (length(sectors) > 1 && "Macro Retail Total (Combined)" %in% sectors) {
      data %>% filter(vertical_name != "Macro Retail Total (Combined)")
    } else {
      data
    }
    
    total_cumulative_sales <- sum(sub_data$Sales, na.rm = TRUE)
    total_months <- length(unique(data$Month))
    date_range <- range(data$Month)
    
    measure_label <- if (input$sales_measure == "sales_nominal") "Nominal ($M)" else "Real (CPI-Adj $M)"
    measure_sub <- if (input$sales_measure == "sales_nominal") "Current Dollars ($M)" else "Chained 1982-84 Dollars ($M)"
    
    fluidRow(
      column(
        4,
        div(
          class = "card text-white bg-primary mb-3 p-3 text-center shadow-sm scorecard-box",
          h6("Total Cumulative Revenue", style = "font-size: 0.85rem; margin-bottom: 2px; text-transform: uppercase; letter-spacing: 0.5px;"),
          h4(paste0("$", comma(round(total_cumulative_sales))), style = "font-weight: 700; margin: 0;"),
          tags$small(paste0("In Millions ($M) | ", total_months, " Months (", format(date_range[1], "%b %Y"), "–", format(date_range[2], "%b %Y"), ")"))
        )
      ),
      column(
        4,
        div(
          class = "card text-white bg-secondary mb-3 p-3 text-center shadow-sm scorecard-box",
          h6("Active Sectors Analyzed", style = "font-size: 0.85rem; margin-bottom: 2px; text-transform: uppercase; letter-spacing: 0.5px;"),
          h4(length(unique(data$vertical_name)), style = "font-weight: 700; margin: 0;"),
          tags$small("Selected retail verticals in view")
        )
      ),
      column(
        4,
        div(
          class = "card text-white bg-success mb-3 p-3 text-center shadow-sm scorecard-box",
          h6("Valuation Metric", style = "font-size: 0.85rem; margin-bottom: 2px; text-transform: uppercase; letter-spacing: 0.5px;"),
          h4(measure_label, style = "font-weight: 700; margin: 0;"),
          tags$small(measure_sub)
        )
      )
    )
  })
  
  # Tab 1 Exploration Plot (TALLER aggregate plot with LOESS trend)
  output$exploration_plot <- renderPlot({
    data <- filtered_data()
    total <- total_data()
    req(nrow(data) > 0)
    
    y_lab <- y_axis_label_tab1()
    scales_setting <- if (input$free_y_scales) "free_y" else "fixed"
    
    if (input$viz_mode == "ts_total") {
      p1 <- data %>%
        ggplot(aes(x = Month, y = Sales, color = vertical_name)) +
        geom_line(linewidth = 0.85) +
        facet_wrap(~ vertical_name, scales = scales_setting, ncol = 2) +
        scale_y_continuous(labels = label_comma(prefix = "$")) +
        scale_color_brewer(palette = "Dark2") +
        theme_minimal(base_size = 13) +
        theme(
          legend.position = "none",
          axis.text.x = element_text(angle = 45, hjust = 1),
          panel.grid.minor = element_blank(),
          strip.text = element_text(face = "bold", size = 11, color = "#145A32")
        ) +
        labs(
          title = paste0("Historical Monthly Retail Sales by Sector — ", y_lab),
          subtitle = "Faceted exploration across selected verticals (values in $M)",
          x = NULL,
          y = y_lab
        )
      
      p2 <- total %>%
        ggplot(aes(x = Month, y = Sales)) +
        geom_line(color = "#1E8449", linewidth = 1) +
        geom_smooth(method = "loess", se = TRUE, color = "#E74C3C", fill = "#FADBD8", alpha = 0.35, linewidth = 0.85) +
        scale_y_continuous(labels = label_comma(prefix = "$")) +
        theme_minimal(base_size = 12) +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1),
          panel.grid.minor = element_blank()
        ) +
        labs(
          title = "Total Aggregate Volume of Selected Verticals with LOESS Trend (in Millions of Dollars - $M)",
          subtitle = "Red curve displays LOESS trend; green line shows actual aggregate sales volume",
          x = "Calendar Month",
          y = "Aggregate ($M)"
        )
      
      p1 / p2 + plot_layout(heights = c(2.2, 1.4))
      
    } else if (input$viz_mode == "stl") {
      stl_fits <- data %>%
        model(STL = STL(Sales ~ season(window = "periodic"))) %>%
        components()
      
      stl_fits %>%
        autoplot() +
        theme_minimal(base_size = 12) +
        theme(
          legend.position = "none",
          axis.text.x = element_text(angle = 45, hjust = 1)
        ) +
        labs(
          title = "STL Decomposition: Trend, Seasonal, and Remainder Components (in $M)",
          subtitle = "Decomposition of monthly series with periodic seasonality",
          x = "Calendar Month",
          y = y_lab
        )
      
    } else if (input$viz_mode == "season") {
      data %>%
        gg_subseries(Sales) +
        scale_y_continuous(labels = label_comma(prefix = "$")) +
        theme_minimal(base_size = 12) +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1),
          panel.grid.minor = element_blank(),
          strip.text = element_text(face = "bold", size = 10, color = "#145A32")
        ) +
        labs(
          title = "Monthly Seasonality Subseries Plot across Calendar Years (in $M)",
          subtitle = "Blue horizontal lines depict monthly historical mean sales across years",
          x = "Calendar Month Subseries",
          y = y_lab
        )
    }
  })
  
  # ============================================================================
  # TAB 2 ENGINE: Model Validation & Backtesting Reactive
  # (Evaluates EXCLUSIVELY on Nominal Retail Sales across all 4 verticals)
  # ============================================================================
  val_results <- reactive({
    val_months <- input$val_horizon
    
    # Fit across all 4 verticals strictly using Nominal Sales (sales_nominal)
    data_all <- raw_retail %>%
      mutate(Sales = as.numeric(sales_nominal)) %>%
      as_tsibble(index = Month, key = vertical_name)
    
    withProgress(
      message = "Estimating validation models on nominal sales...",
      detail = "Fitting TSLM, ETS, and ARIMA across pre-validation training window",
      value = 0.25,
      {
        training_data <- data_all %>%
          group_by(vertical_name) %>%
          arrange(Month) %>%
          slice_head(n = -val_months) %>%
          ungroup() %>%
          as_tsibble(index = Month, key = vertical_name)
        
        incProgress(0.35, detail = "Optimizing parameters...")
        
        models <- training_data %>%
          model(
            TSLM = TSLM(Sales ~ trend() + season()),
            ETS = ETS(Sales),
            ARIMA = ARIMA(Sales)
          ) %>%
          mutate(Combo = (TSLM + ETS + ARIMA) / 3)
        
        incProgress(0.25, detail = "Scoring validation accuracy...")
        
        val_forecasts <- models %>% forecast(h = val_months)
        train_accuracy <- models %>% accuracy()
        val_accuracy <- val_forecasts %>% accuracy(data_all)
        
        list(
          models = models,
          training_data = training_data,
          full_data = data_all,
          val_forecasts = val_forecasts,
          train_accuracy = train_accuracy,
          val_accuracy = val_accuracy,
          val_months = val_months
        )
      }
    )
  })
  
  # Tab 2 Training / Validation Window Banner Display
  output$modeling_window_banner <- renderUI({
    res <- val_results()
    req(res)
    
    train_dates <- range(res$training_data$Month)
    val_data <- res$full_data %>%
      group_by(vertical_name) %>%
      arrange(Month) %>%
      slice_tail(n = res$val_months) %>%
      ungroup()
    val_dates <- range(val_data$Month)
    
    div(
      class = "p-2 bg-light border border-success rounded text-center",
      style = "font-size: 0.95rem;",
      span(strong("Training Window: "), format(train_dates[1], "%b %Y"), " to ", format(train_dates[2], "%b %Y"), 
           paste0(" (", length(unique(res$training_data$Month)), " months)")),
      span("  |  ", style = "color: #1E8449; font-weight: bold;"),
      span(strong("Validation Window: "), format(val_dates[1], "%b %Y"), " to ", format(val_dates[2], "%b %Y"),
           paste0(" (", res$val_months, " months held out)")),
      span("  |  ", style = "color: #1E8449; font-weight: bold;"),
      span(strong("Valuation Basis: "), span("Nominal Retail Sales ($M) only", style = "color: #145A32; font-weight: bold;"))
    )
  })
  
  # Tab 2 Model Specifications Table (Rendered inside collapsible <details>)
  output$model_specs_table <- renderUI({
    res <- val_results()
    req(res)
    
    specs_df <- res$models %>%
      as_tibble() %>%
      mutate(
        TSLM_Form = "Sales ~ trend() + season()",
        ETS_Form = purrr::map_chr(ETS, ~ gsub("[<>]", "", format(.x))),
        ARIMA_Form = purrr::map_chr(ARIMA, ~ gsub("[<>]", "", format(.x))),
        Combo_Form = "Equal average of (TSLM + ETS + ARIMA) / 3"
      ) %>%
      select(
        Vertical = vertical_name,
        `TSLM Specification` = TSLM_Form,
        `ETS Component Form` = ETS_Form,
        `ARIMA Orders` = ARIMA_Form,
        `Ensemble Model` = Combo_Form
      )
    
    specs_df %>%
      gt() %>%
      tab_header(
        title = "Model Specification Table",
        subtitle = "Optimal auto-specified model architectures across all four retail series"
      ) %>%
      tab_style(
        style = list(cell_text(weight = "bold", color = "#145A32")),
        locations = cells_column_labels()
      ) %>%
      tab_options(
        table.width = pct(100),
        table.font.size = px(13)
      ) %>%
      as_raw_html()
  })
  
  # Tab 2 Combined In-Sample & Out-of-Sample Accuracy Table (WITH COLOR CODING BY OUT-OF-SAMPLE)
  output$combined_accuracy_table <- renderUI({
    res <- val_results()
    req(res)
    
    series_to_show <- input$val_series_to_plot %||% vertical_choices
    metric <- input$metric_choice
    sort_vert <- input$sort_vertical
    
    t_acc <- res$train_accuracy %>%
      filter(vertical_name %in% series_to_show) %>%
      as_tibble() %>%
      select(vertical_name, .model, train_metric = all_of(metric))
    
    v_acc <- res$val_accuracy %>%
      filter(vertical_name %in% series_to_show) %>%
      as_tibble() %>%
      select(vertical_name, .model, val_metric = all_of(metric))
    
    # Compute RdYlGn color palette per vertical based strictly on Out-of-Sample validation error
    joined <- inner_join(v_acc, t_acc, by = c("vertical_name", ".model"))
    
    colored_joined <- joined %>%
      group_by(vertical_name) %>%
      mutate(
        color_val = col_numeric(
          palette = c("#D4EFDF", "#FCF3CF", "#FADBD8"), 
          domain = range(val_metric)
        )(val_metric),
        cell_display = paste0(
          "<div style=\"background-color: ", color_val, "; padding: 6px 10px; border-radius: 4px; font-weight: 600; text-align: center;\">",
          trimws(format(round(val_metric, 1), nsmall = 1)),
          " <span style=\"font-weight: normal; color: #4A5568;\">(",
          trimws(format(round(train_metric, 1), nsmall = 1)),
          ")</span></div>"
        )
      ) %>%
      ungroup()
    
    wide_df <- colored_joined %>%
      select(vertical_name, .model, cell_display) %>%
      pivot_wider(names_from = vertical_name, values_from = cell_display) %>%
      rename(Model = .model)
    
    # Sort strictly by out-of-sample error in the chosen sort_vertical
    if (!is.null(sort_vert) && sort_vert %in% names(wide_df)) {
      order_keys <- joined %>%
        filter(vertical_name == sort_vert) %>%
        arrange(val_metric) %>%
        pull(.model)
      wide_df <- wide_df %>% arrange(match(Model, order_keys))
    }
    
    wide_df %>%
      gt() %>%
      tab_header(
        title = paste("Combined Model Performance Comparison —", metric, "(Nominal Sales in $M)"),
        subtitle = paste0("Format: Out-of-Sample Validation Error (In-Sample Training Error in Parentheses) | ", res$val_months, "-Month Horizon")
      ) %>%
      fmt_markdown(columns = everything()) %>%
      tab_style(
        style = list(cell_text(weight = "bold", color = "#145A32")),
        locations = cells_column_labels()
      ) %>%
      tab_style(
        style = list(cell_text(weight = "bold", color = "#145A32")),
        locations = cells_body(columns = Model)
      ) %>%
      tab_footnote(
        footnote = paste0("Units: ", metric, " in Nominal Millions of Dollars ($M) [MAPE in %]. Color coded by Out-of-Sample error (Green = Lowest Error / Best Accuracy, Red = Highest Error). In-sample training error in parentheses."),
        locations = cells_column_labels(columns = -Model)
      ) %>%
      tab_options(table.width = pct(100)) %>%
      as_raw_html()
  })
  
  # Tab 2 Validation Backtest Plot (Each on Its Own Row and Larger)
  output$validation_backtest_plot <- renderPlot({
    res <- val_results()
    req(res)
    
    series_to_show <- input$val_series_to_plot %||% vertical_choices
    
    val_fc <- res$val_forecasts %>% filter(vertical_name %in% series_to_show)
    
    # Show recent 2 years of data plus validation actuals
    val_data <- res$full_data %>%
      filter(vertical_name %in% series_to_show) %>%
      group_by(vertical_name) %>%
      slice_tail(n = res$val_months + 12) %>%
      ungroup() %>%
      as_tsibble(index = Month, key = vertical_name)
    
    val_fc %>%
      autoplot(level = NULL, linewidth = 0.95) +
      autolayer(val_data, Sales, color = "black", linewidth = 1.1) +
      facet_wrap(~ vertical_name, scales = "free_y", ncol = 1) +  # EACH ON ITS OWN ROW
      scale_y_continuous(labels = label_comma(prefix = "$")) +
      scale_color_brewer(palette = "Set1") +
      theme_minimal(base_size = 13) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid.minor = element_blank(),
        legend.position = "bottom",
        strip.text = element_text(face = "bold", size = 12, color = "#145A32")
      ) +
      labs(
        title = paste0("Validation Backtest: ", res$val_months, "-Month Out-of-Sample Forecast vs. Actuals — Nominal Sales ($M)"),
        subtitle = "Black line shows actual sales observations ($M); colored lines show out-of-sample model predictions on Nominal Sales",
        x = "Calendar Month",
        y = "Nominal Sales (Millions of Current Dollars - $M)",
        color = "Forecasting Model"
      )
  })
  
  # Tab 2 Diagnostic Insights Text Output
  output$model_insights_text <- renderUI({
    res <- val_results()
    req(res)
    
    tagList(
      p(
        strong("Model Performance Comparison: "),
        "Across discretionary and volatile retail sectors (such as Clothing and Building Materials), ",
        strong("Seasonal ARIMA"), " and ", strong("ETS"), " state-space models consistently achieve substantially lower out-of-sample validation error than ",
        strong("TSLM"), ". TSLM forces deterministic linear trend slopes and rigid fixed-amplitude seasonal dummy coefficients, ",
        "rendering it unable to adjust to evolving seasonal variance or post-recession trend shifts. ",
        "For steady, essential staple categories (Health & Personal Care) and the Macro Retail composite, ETS and ARIMA capture smooth compounding volume with high precision."
      ),
      p(
        strong("Ensemble Benefits: "),
        "The equal-weighted ", strong("Combo model"), " provides an attractive risk-diversified alternative, ",
        "frequently scoring close to the lowest RMSE while protecting against individual model misspecification."
      )
    )
  })
  
  # ============================================================================
  # TAB 3 ENGINE: Production Forward Forecasting Reactive
  # (Evaluates EXCLUSIVELY on Nominal Retail Sales across all 4 verticals)
  # ============================================================================
  
  # Fit production models across ALL 4 series through August 2026 strictly on nominal sales
  prod_models <- reactive({
    data_all <- raw_retail %>%
      mutate(Sales = as.numeric(sales_nominal)) %>%
      as_tsibble(index = Month, key = vertical_name)
    
    withProgress(
      message = "Generating production forward forecasts on nominal sales...",
      detail = "Estimating models on full historical data through August 2026",
      value = 0.3,
      {
        models <- data_all %>%
          model(
            TSLM = TSLM(Sales ~ trend() + season()),
            ETS = ETS(Sales),
            ARIMA = ARIMA(Sales)
          ) %>%
          mutate(Combo = (TSLM + ETS + ARIMA) / 3)
        
        incProgress(0.7)
        list(
          models = models, 
          data = data_all
        )
      }
    )
  })
  
  # Fit Tab 3 backtest models strictly controlled by input$fc_horizon (decoupled from Tab 2)
  fc_backtest_models <- reactive({
    req(input$fc_horizon)
    h_months <- input$fc_horizon
    
    data_all <- raw_retail %>%
      mutate(Sales = as.numeric(sales_nominal)) %>%
      as_tsibble(index = Month, key = vertical_name)
    
    withProgress(
      message = "Estimating comparative backtest models on nominal sales...",
      detail = paste0("Holding out last ", h_months, " months for validation"),
      value = 0.3,
      {
        training_data <- data_all %>%
          group_by(vertical_name) %>%
          arrange(Month) %>%
          slice_head(n = -h_months) %>%
          ungroup() %>%
          as_tsibble(index = Month, key = vertical_name)
        
        models <- training_data %>%
          model(
            TSLM = TSLM(Sales ~ trend() + season()),
            ETS = ETS(Sales),
            ARIMA = ARIMA(Sales)
          ) %>%
          mutate(Combo = (TSLM + ETS + ARIMA) / 3)
        
        incProgress(0.7)
        list(
          models = models,
          training_data = training_data,
          full_data = data_all,
          h_months = h_months
        )
      }
    )
  })
  
  # Tab 3 Mode Banner
  output$fc_mode_banner <- renderUI({
    if (input$fc_mode == "future") {
      prod <- prod_models()
      max_m <- max(raw_retail$Month)
      fc_start <- max_m + 1
      fc_end <- max_m + input$fc_horizon
      
      div(
        class = "alert alert-success p-2 mb-2",
        style = "font-size: 0.92rem; background-color: #EAFAF1; border-color: #A9DFBF; color: #145A32;",
        icon("calendar-alt"),
        strong(" Forward Planning Mode: "),
        paste0("Models estimated through ", format(max_m, "%B %Y"), " (all 416 months, values in Nominal $M). "),
        paste0("Projecting ", input$fc_horizon, " months into the unobserved future: ",
               format(fc_start, "%b %Y"), " – ", format(fc_end, "%b %Y"), ". "),
        tags$span(style = "font-weight: bold; color: #145A32;", "| Basis: Nominal Sales ($M) only")
      )
    } else {
      bt <- fc_backtest_models()
      max_m <- max(raw_retail$Month)
      val_start <- max_m - input$fc_horizon + 1
      
      div(
        class = "alert alert-warning p-2 mb-2",
        style = "font-size: 0.92rem;",
        icon("history"),
        strong(" Validation Backtest Mode: "),
        paste0("Displaying models trained on pre-validation data and evaluated over the ", 
               input$fc_horizon, "-month validation window (",
               format(val_start, "%b %Y"), " – ", format(max_m, "%b %Y"),
               ") with actual held-out data overlaid (values in Nominal $M). "),
        tags$span(style = "font-weight: bold; color: #856404;", "| Basis: Nominal Sales ($M) only")
      )
    }
  })
  
  # Tab 3 Comparative Forecast Plot (Overlay mode: each vertical on its own row; Grid mode: Model x Vertical)
  output$forecast_plot <- renderPlot({
    req(input$models_to_plot, input$fc_series_to_plot)
    
    ci_levels_numeric <- as.numeric(input$ci_levels)
    if (length(ci_levels_numeric) == 0) ci_levels_numeric <- NULL
    
    if (input$fc_mode == "future") {
      # FORWARD PLANNING: models fit on 100% of data through August 2026
      prod <- prod_models()
      req(prod)
      
      models_full <- prod$models %>% filter(vertical_name %in% input$fc_series_to_plot)
      # Always retain vertical_name in select so tsibble key structure is preserved for 1 or more verticals
      selected_models <- models_full %>% select(vertical_name, any_of(input$models_to_plot))
      fc <- selected_models %>% forecast(h = input$fc_horizon)
      
      data_full <- prod$data %>% filter(vertical_name %in% input$fc_series_to_plot)
      display_history <- data_full %>%
        group_by(vertical_name) %>%
        slice_tail(n = 12 * input$years_display) %>%
        ungroup() %>%
        as_tsibble(index = Month, key = vertical_name)
      
      if (input$fc_layout == "overlay") {
        # OVERLAY: EACH VERTICAL ON ITS OWN ROW
        p <- fc %>%
          autoplot(display_history, level = NULL, linewidth = 0.95) +
          facet_wrap(~ vertical_name, scales = "free_y", ncol = 1) +  # EACH ON ITS OWN ROW
          scale_y_continuous(labels = label_comma(prefix = "$")) +
          scale_color_brewer(palette = "Set1") +
          theme_minimal(base_size = 13) +
          theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            panel.grid.minor = element_blank(),
            legend.position = "bottom",
            strip.text = element_text(face = "bold", size = 12, color = "#145A32")
          ) +
          labs(
            title = paste0(input$fc_horizon, "-Month Ahead Forward Model Overlay (2026–2027+) — Nominal Sales ($M)"),
            subtitle = paste0("Comparative model projections starting from latest actuals (Aug 2026); past ", input$years_display, " years of actuals overlaid ($M)"),
            x = "Calendar Month",
            y = "Nominal Sales (Millions of Current Dollars - $M)",
            color = "Model"
          )
        p
      } else {
        # FACETED GRID: Model x Vertical
        p <- fc %>%
          autoplot(level = ci_levels_numeric) +
          autolayer(display_history, Sales, color = "black", linewidth = 0.7) +
          facet_grid(.model ~ vertical_name, scales = "free_y") +
          scale_y_continuous(labels = label_comma(prefix = "$")) +
          theme_minimal(base_size = 12) +
          theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            panel.grid.minor = element_blank(),
            strip.text = element_text(face = "bold", size = 10, color = "#145A32")
          ) +
          labs(
            title = paste0(input$fc_horizon, "-Month Ahead Future Retail Sales Projections (2026–2027+) — Nominal Sales ($M)"),
            subtitle = paste0("Black line shows last ", input$years_display, " years of actual sales through Aug 2026; shaded ribbons show forward prediction intervals"),
            x = "Calendar Month",
            y = "Nominal Sales (Millions of Current Dollars - $M)"
          )
        p
      }
      
    } else {
      # BACKTEST MODE (Driven strictly by input$fc_horizon on Tab 3)
      bt <- fc_backtest_models()
      req(bt)
      
      models_val <- bt$models %>% filter(vertical_name %in% input$fc_series_to_plot)
      # Always retain vertical_name in select so tsibble key structure is preserved for 1 or more verticals
      selected_models <- models_val %>% select(vertical_name, any_of(input$models_to_plot))
      fc <- selected_models %>% forecast(h = input$fc_horizon)
      
      data_val <- bt$full_data %>% filter(vertical_name %in% input$fc_series_to_plot)
      display_history <- data_val %>%
        group_by(vertical_name) %>%
        slice_tail(n = 12 * input$years_display) %>%
        ungroup() %>%
        as_tsibble(index = Month, key = vertical_name)
      
      if (input$fc_layout == "overlay") {
        # OVERLAY: EACH ON ITS OWN ROW
        p <- fc %>%
          autoplot(display_history, level = NULL, linewidth = 0.95) +
          facet_wrap(~ vertical_name, scales = "free_y", ncol = 1) +  # EACH ON ITS OWN ROW
          scale_y_continuous(labels = label_comma(prefix = "$")) +
          scale_color_brewer(palette = "Set1") +
          theme_minimal(base_size = 13) +
          theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            panel.grid.minor = element_blank(),
            legend.position = "bottom",
            strip.text = element_text(face = "bold", size = 12, color = "#145A32")
          ) +
          labs(
            title = paste0(input$fc_horizon, "-Month Backtest Overlay Comparison — Nominal Sales ($M)"),
            subtitle = paste0("Comparing model forecast paths against actual held-out validation sales ($M) over the last ", input$fc_horizon, " months"),
            x = "Calendar Month",
            y = "Nominal Sales (Millions of Current Dollars - $M)",
            color = "Model"
          )
        p
      } else {
        # FACETED GRID: Model x Vertical
        p <- fc %>%
          autoplot(level = ci_levels_numeric) +
          autolayer(display_history, Sales, color = "black", linewidth = 0.7) +
          facet_grid(.model ~ vertical_name, scales = "free_y") +
          scale_y_continuous(labels = label_comma(prefix = "$")) +
          theme_minimal(base_size = 12) +
          theme(
            axis.text.x = element_text(angle = 45, hjust = 1),
            panel.grid.minor = element_blank(),
            strip.text = element_text(face = "bold", size = 10, color = "#145A32")
          ) +
          labs(
            title = paste0(input$fc_horizon, "-Month Backtest Forecasts with Prediction Intervals — Nominal Sales ($M)"),
            subtitle = paste0("Black line shows actual sales ($M) including held-out ", input$fc_horizon, "-month validation window"),
            x = "Calendar Month",
            y = "Nominal Sales (Millions of Current Dollars - $M)"
          )
        p
      }
    }
  })
  
  # Reactive expression to compute forecast results and prediction intervals
  forecast_clean_data <- reactive({
    req(input$models_to_plot, input$fc_series_to_plot)
    
    if (input$fc_mode == "future") {
      prod <- prod_models()
      req(prod)
      models_full <- prod$models %>% filter(vertical_name %in% input$fc_series_to_plot)
      selected_models <- models_full %>% select(vertical_name, any_of(input$models_to_plot))
      fc <- selected_models %>% forecast(h = input$fc_horizon)
    } else {
      bt <- fc_backtest_models()
      req(bt)
      models_val <- bt$models %>% filter(vertical_name %in% input$fc_series_to_plot)
      selected_models <- models_val %>% select(vertical_name, any_of(input$models_to_plot))
      fc <- selected_models %>% forecast(h = input$fc_horizon)
    }
    
    fc_intervals <- hilo(fc, level = c(80, 95))
    h80 <- fc_intervals$`80%`
    h95 <- fc_intervals$`95%`
    
    fc_intervals %>%
      as_tibble() %>%
      mutate(
        Month_Str = format(Month, "%Y %b"),
        Point_Forecast_M = round(.mean, 2),
        Lower_80_M = round(h80$lower, 2),
        Upper_80_M = round(h80$upper, 2),
        Lower_95_M = round(h95$lower, 2),
        Upper_95_M = round(h95$upper, 2),
        `Point Forecast (Nominal $M)` = paste0("$", comma(round(.mean))),
        `80% Interval (Nominal $M)` = paste0("[$", comma(round(h80$lower)), " – $", comma(round(h80$upper)), "]"),
        `95% Interval (Nominal $M)` = paste0("[$", comma(round(h95$lower)), " – $", comma(round(h95$upper)), "]")
      )
  })
  
  # Tab 3 Forecast Data Table (CLEAN FORMATTING: Currency in Millions and Intervals)
  output$forecast_table <- DT::renderDT({
    df <- forecast_clean_data()
    req(df)
    
    display_df <- df %>%
      select(
        Vertical = vertical_name,
        Model = .model,
        Month = Month_Str,
        `Point Forecast (Nominal $M)`,
        `80% Interval (Nominal $M)`,
        `95% Interval (Nominal $M)`
      )
    
    DT::datatable(
      display_df,
      options = list(pageLength = 8, scrollX = TRUE, autoWidth = TRUE),
      rownames = FALSE,
      filter = "top"
    )
  })
  
  # Download Handler for Forecast Data Table (CSV)
  output$download_forecast_csv <- downloadHandler(
    filename = function() {
      mode_str <- if (input$fc_mode == "future") {
        paste0("forward_planning_", input$fc_horizon, "m")
      } else {
        paste0("validation_backtest_", input$fc_horizon, "m")
      }
      paste0("us_retail_forecasts_", mode_str, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      df <- forecast_clean_data()
      req(df)
      export_df <- df %>%
        select(
          Vertical = vertical_name,
          Model = .model,
          Month = Month_Str,
          Point_Forecast_Nominal_M = Point_Forecast_M,
          Lower_80_Nominal_M = Lower_80_M,
          Upper_80_Nominal_M = Upper_80_M,
          Lower_95_Nominal_M = Lower_95_M,
          Upper_95_Nominal_M = Upper_95_M,
          Interval_80_Display = `80% Interval (Nominal $M)`,
          Interval_95_Display = `95% Interval (Nominal $M)`
        )
      write_csv(export_df, file)
    }
  )
}

# ------------------------------------------------------------------------------
# 4. App Launch
# ------------------------------------------------------------------------------

shinyApp(ui = ui, server = server)
