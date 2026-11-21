# ==============================================================================
# ADS 506 Module 5: Shiny App Deployment Helper (shinyapps.io)
# ==============================================================================
#
# Instructions to deploy your Shiny app to shinyapps.io:
#
# 1. Sign up or log in to your free account at: https://www.shinyapps.io
# 2. Go to: Account -> Tokens -> Show -> Copy to clipboard
#    It will look like:
#    rsconnect::setAccountInfo(
#      name='<YOUR_ACCOUNT_NAME>',
#      token='<YOUR_TOKEN>',
#      secret='<YOUR_SECRET>'
#    )
# 3. Paste and run that command in the R console once.
# 4. Run the deployApp() function below from inside the "Module 5" directory!
# ==============================================================================

library(rsconnect)

# Optional: verify your connected accounts
cat("Configured rsconnect accounts:\n")
print(rsconnect::accounts())

# Deploy the Module 5 app to shinyapps.io
# Note: Ensure you run this while setwd() is in the "Module 5" folder!
# (or provide appDir = "Module 5")

app_directory <- if (file.exists("app.R")) "." else "Module 5"

cat("\nDeploying application from:", app_directory, "...\n")

rsconnect::deployApp(
  appDir = app_directory,
  appFiles = c("app.R", "about.md", "data/retail_data_clean.csv"),
  appName = "ads506-retail-forecasting-app",
  appTitle = "U.S. Retail Sales Time Series & Forecasting Dashboard",
  forceUpdate = TRUE
)

cat("\nDeployment complete! Copy your published URL and paste it into Week5_Submission_Template.qmd.\n")
