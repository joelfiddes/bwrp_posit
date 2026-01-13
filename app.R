library(shiny)
library(sf)
library(leaflet)
library(dplyr)
library(readr)
library(ggplot2)
library(viridisLite)
library(RColorBrewer)
library(zoo)
library(tidyr)
library(fst)
library(tibble)

# =======================
# CLIMATE FORCING DATA
# =======================

# Load climate forcing data
cf_data_path <- "./data/current_climate/catchments_with_forcing.csv"
cf_catchments <- read.csv(cf_data_path)
cf_catchments$Annual_TP_mm <- cf_catchments$TP_mmhr * 24 * 365
cf_catchments$PET_mm_annual_priestly <- cf_catchments$PET_mm_hr_priestly * 8760
cf_catchments$PET_mm_annual_penman   <- cf_catchments$PET_mm_hr_penman   * 8760
cf_catchments <- st_as_sf(cf_catchments, wkt = "geometry", crs = 4326)

# Climate Forcing Variable Dictionary
cf_group_order <- c("Temperature", "Precipitation", "Radiation", "Humidity & Wind", "Evaporation", "Other")

cf_var_dict <- tibble::tribble(
  ~var,                      ~label,                                ~unit,           ~group,                ~vmin,  ~vmax, ~palette,
  "Tair_C",                  "Air Temperature",                     "°C",            "Temperature",         -10,    45,    "inferno",
  "Tsurf",                   "Surface Temperature",                 "°C",            "Temperature",         -10,    50,    "inferno",
  
  "TP_mmhr",                 "Total Precipitation",                 "mm/hr",         "Precipitation",       0,      5,     "viridis",
  "Sf_mmhr",                 "Snowfall",                            "mm/hr",         "Precipitation",       0,      2,     "viridis",
  "Rf_mmhr",                 "Rainfall",                            "mm/hr",         "Precipitation",       0,      5,     "viridis",
  "Annual_TP_mm",            "Annual Precipitation",                "mm/year",       "Precipitation",       0,      2000,  "viridis",
  
  "LWin",                    "Incoming Longwave Radiation",         "W/m²",          "Radiation",           100,    400,   "viridis",
  "SWin",                    "Incoming Shortwave Radiation",        "W/m²",          "Radiation",           0,      350,   "viridis",
  "LWout",                   "Outgoing Longwave Radiation",         "W/m²",          "Radiation",           200,    500,   "viridis",
  "LWnet",                   "Net Longwave Radiation",              "W/m²",          "Radiation",           -150,   50,    "RdBu",
  "SWnet",                   "Net Shortwave Radiation",             "W/m²",          "Radiation",           -50,    250,   "viridis",
  "Rnet_Wm2",                "Net Radiation",                       "W/m²",          "Radiation",           -100,   300,   "viridis",
  "Rnet_MJm2hr",             "Net Radiation",                       "MJ/m²/hr",      "Radiation",           0,      1.2,   "viridis",
  
  "RH",                      "Relative Humidity",                   "%",             "Humidity & Wind",     10,     100,   "viridis",
  "wind_ms",                 "Wind Speed",                          "m/s",           "Humidity & Wind",     0,      10,    "viridis",
  
  "PET_mm_hr_penman",        "Penman PET",                          "mm/hr",         "Evaporation",         0,      0.5,   "viridis",
  "PET_mm_hr_priestly",      "Priestly-Taylor PET",                 "mm/hr",         "Evaporation",         0,      0.5,   "viridis",
  "PET_mm_annual_penman",    "Annual PET (Penman)",                 "mm/year",       "Evaporation",         0,      3000,  "viridis",
  "PET_mm_annual_priestly",  "Annual PET (Priestly-Taylor)",        "mm/year",       "Evaporation",         0,      3000,  "viridis",
  
  "delta",                   "Clausius-Clapeyron Slope",            "kPa/°C",        "Other",               0,      0.5,   "viridis"
)

cf_var_dict$group <- factor(cf_var_dict$group, levels = cf_group_order)
cf_var_dict <- cf_var_dict[order(cf_var_dict$group, cf_var_dict$var), ]
cf_var_dict <- cf_var_dict %>%
  mutate(display_name = paste0(label, " [", unit, "]"))

# =======================
# CLIMATE CHANGE DATA
# =======================

cc_base_shp <- "./data/future_climate/modelcatchments.shp"

cc_scenario_dirs <- list(
  "SSP1-2.6" = "./data/future_climate/data_ssp126",
  "SSP2-4.5" = "./data/future_climate/data_ssp245",
  "SSP5-8.5" = "./data/future_climate/data_ssp585"
)

cc_hist_dir <- "./data/future_climate/data_hist"
cc_by_period_subdir <- "by_period"

cc_ts_scenario_dirs <- list(
  "SSP1-2.6" = "./data/future_climate/data_fst_weekly/ssp126",
  "SSP2-4.5" = "./data/future_climate/data_fst_weekly/ssp245",
  "SSP5-8.5" = "./data/future_climate/data_fst_weekly/ssp585"
)

cc_ts_hist_dir <- "./data/future_climate/data_fst_weekly/hist"

# Variable dictionary
group_order <- c("Temperature", "Precipitation", "Radiation", "Hydrology", 
                 "Snow", "Soil", "Energy", "Humidity", "Wind", "Evaporation", "Time")

cc_var_dict <- tibble::tribble(
  ~var,                     ~label,                        ~unit,           ~group,            ~vmin,  ~vmax, ~palette,
  "Tair_C",                 "Air temperature",              "°C",          "Temperature",     4,     40,  "inferno",
  "Tsurf",                  "Surface temperature",          "°C",          "Temperature",    -5,     40,  "inferno",
  "TP_mmhr",                "Total precipitation rate",     "mm/hr",       "Precipitation",   0,       5,  "viridis",
  "Sf_mmhr",                "Snowfall rate",                "mm/hr",       "Precipitation",   0,       2,  "viridis",
  "Rf_mmhr",                "Rainfall rate",                "mm/hr",       "Precipitation",   0,       5,  "viridis",
  "Prain",                  "Precipitation (rain)",         "mm",          "Precipitation",   0,      500,  "viridis",
  "Psnow",                  "Precipitation (snow)",         "mm",          "Precipitation",   0,      500,  "viridis",
  "TP_mm",                  "Total precipitation",          "mm",          "Precipitation",   0,     500,  "viridis",
  "annual_precip_mm",       "Annual precipitation",         "mm",          "Precipitation",   0,    2000,  "viridis",
  "LWin",                   "Incoming longwave radiation",  "W m⁻²",       "Radiation",        100,    400,  "viridis",
  "SWin",                   "Incoming shortwave radiation", "W m⁻²",       "Radiation",        0,      350,  "viridis",
  "LWout",                  "Outgoing longwave radiation",  "W m⁻²",       "Radiation",       200,    450,  "viridis",
  "LWnet",                  "Net longwave radiation",       "W m⁻²",       "Radiation",      -150,     50,  "viridis",
  "SWnet",                  "Net shortwave radiation",      "W m⁻²",       "Radiation",       -50,    250,  "viridis",
  "Rnet_Wm2",               "Net radiation",                "W m⁻²",       "Radiation",      -150,    300,  "viridis",
  "Rnet_MJm2hr",            "Net radiation",                "MJ m⁻² hr⁻¹", "Radiation",        0,      1,  "viridis",
  "Msnow",                  "Snowmelt",                     "mm",          "Hydrology",       0,       20,  "viridis",
  "Total",                  "Total runoff",                 "mm",          "Hydrology",       0,      100,  "viridis",
  "Rech",                   "Recharge",                     "mm",          "Hydrology",       0,       50,  "viridis",
  "Eac",                    "Actual evapotranspiration",    "mm",          "Hydrology",       0,       50,  "viridis",
  "SM",                     "Soil moisture",                "mm",          "Hydrology",       0,      300,  "viridis",
  "q_sim",                  "Simulated discharge",          "m³/s",        "Hydrology",       0,     100,  "viridis",
  "WB",                     "Water balance",                "mm",          "Hydrology",      -50,      50,  "viridis",
  "annual_water_budget_mm", "Annual water budget",         "mm",          "Hydrology",      -500,   500,  "viridis",
  "SWE",                    "Snow water equivalent",        "mm",          "Hydrology",            0,      1000, "viridis",
  "STZ",                    "Surface top zone",             "mm",          "Hydrology",            0,      200,  "viridis",
  "SUZ",                    "Subsurface upper zone",        "mm",          "Hydrology",            0,      500,  "viridis",
  "SLZ",                    "Subsurface lower zone",        "mm",          "Hydrology",            0,     1000,  "viridis",
  "Qg",                     "Ground heat flux",             "W m⁻²",       "Hydrology",         -50,      50,  "viridis",
  "Q0",                     "Energy flux Q0",               "W m⁻²",       "Hydrology",         -50,      50,  "viridis",
  "Q1",                     "Energy flux Q1",               "W m⁻²",       "Hydrology",         -50,      50,  "viridis",
  "Q2",                     "Energy flux Q2",               "W m⁻²",       "Hydrology",         -50,      50,  "viridis",
  "RH",                     "Relative humidity",            "%",           "Humidity",        10,     100,  "viridis",
  "wind_ms",                "Wind speed",                   "m/s",         "Wind",             0,      10,  "viridis",
  "PET_mm_hr_penman",       "PET Penman",                   "mm/hr",       "Evaporation",     0,       0.5,  "viridis",
  "PET_mm_hr_priestly",     "PET Priestley-Taylor",         "mm/hr",       "Evaporation",     0,       0.5,  "viridis"
)

cc_var_dict$group <- factor(cc_var_dict$group, levels = group_order)
cc_var_dict <- cc_var_dict[order(cc_var_dict$group, cc_var_dict$var), ]

cc_base_catchments <- st_read(cc_base_shp, quiet = TRUE) %>%
  mutate(row_id = row_number())

cc_base_fields <- names(st_drop_geometry(cc_base_catchments))

cc_get_shp_path <- function(scenario, mode, period, season) {
  base_dir <- cc_scenario_dirs[[scenario]]
  bp <- file.path(base_dir, cc_by_period_subdir)
  
  if (mode == "absolute") {
    file.path(bp, paste0(period, "_", season, "_shp.shp"))
  } else {
    file.path(bp, paste0("diff_2070-2100_vs_hist_", season, ".shp"))
  }
}

# =======================
# WATER RESOURCES DATA
# =======================

wrm_catchments <- st_read("./data/hydrology/inputs/modelcatchments.shp", quiet = TRUE) %>%
  mutate(index = row_number() - 1)

wrm_anomaly_df <- read_csv("./data/hydrology/inputs/anomaly_df.csv", show_col_types = FALSE)

# Water Resources Variable Dictionary
wrm_group_order <- c("Precipitation", "Snow", "Hydrology", "Soil Zones", "Discharge")

wrm_var_dict <- tibble::tribble(
  ~var,     ~label,                           ~unit,     ~group,            ~palette,
  "Prain",  "Rainfall",                       "mm",      "Precipitation",   "viridis",
  "Psnow",  "Snowfall",                       "mm",      "Precipitation",   "viridis",
  "Total",  "Total Precipitation",            "mm",      "Precipitation",   "viridis",
  
  "SWE",    "Snow Water Equivalent",          "mm",      "Snow",            "viridis",
  "Msnow",  "Snow Melt",                      "mm",      "Snow",            "viridis",
  
  "Rech",   "Recharge",                       "mm",      "Hydrology",       "viridis",
  "Eac",    "Actual Evapotranspiration",      "mm",      "Hydrology",       "viridis",
  "SM",     "Soil Moisture",                  "mm",      "Hydrology",       "viridis",
  "Qg",     "Groundwater Flow",               "mm",      "Hydrology",       "viridis",
  "Q0",     "Runoff Q0",                      "mm",      "Hydrology",       "viridis",
  "Q1",     "Runoff Q1",                      "mm",      "Hydrology",       "viridis",
  "Q2",     "Runoff Q2",                      "mm",      "Hydrology",       "viridis",
  "WB",     "Water Balance",                  "mm",      "Hydrology",       "viridis",
  
  "STZ",    "Shallow Soil Zone",              "mm",      "Soil Zones",      "viridis",
  "SUZ",    "Surface Unsaturated Zone",       "mm",      "Soil Zones",      "viridis",
  "SLZ",    "Subsurface Unsaturated Zone",    "mm",      "Soil Zones",      "viridis",
  
  "q_sim",  "Simulated Discharge",            "m³/s",    "Discharge",       "viridis"
)

wrm_var_dict$group <- factor(wrm_var_dict$group, levels = wrm_group_order)
wrm_var_dict <- wrm_var_dict[order(wrm_var_dict$group, wrm_var_dict$var), ]
wrm_var_dict <- wrm_var_dict %>%
  mutate(display_name = paste0(label, " (", unit, ")"))

wrm_variable_names <- setNames(wrm_var_dict$display_name, wrm_var_dict$var)

wrm_anomaly_df <- wrm_anomaly_df %>%
  mutate(variable = recode(variable, !!!wrm_variable_names))

# =======================
# UI
# =======================

ui <- navbarPage(
  "BWRP Dashboard",
  
  # =======================
  # TAB 1: Current Climate
  # =======================
  tabPanel("Current Climate",
    fluidPage(
      titlePanel("Baluchistan Current Climate"),
      sidebarLayout(
        sidebarPanel(
          fluidRow(
            column(
              10,
              h4("Current Climate")
            ),
            column(
              2,
              br(),
              actionButton(
                "cf_info_btn", "",
                icon = icon("info-circle"),
                style = "margin-top: 5px;"
              )
            )
          ),
          
          selectInput("cf_selected_var", "Select Variable:",
                      choices = character(0)),
          
          sliderInput(
            "cf_alpha", "Polygon transparency:",
            min = 0, max = 1, value = 0.8, step = 0.05
          ),
          
          selectInput(
            "cf_basemap", "Basemap:",
            choices = c(
              "Light" = "CartoDB.Positron",
              "Topographic" = "Esri.WorldTopoMap"
            )
          )
        ),
        mainPanel(
          leafletOutput("cf_map", height = "800px")
        )
      )
    )
  ),
  
  # =======================
  # TAB 2: Current Hydrology
  # =======================
  tabPanel("Current Hydrology",
    fluidPage(
      titlePanel("Baluchistan Current Hydrology"),
      sidebarLayout(
        sidebarPanel(
          fluidRow(
            column(
              10,
              h4("Current Hydrology")
            ),
            column(
              2,
              br(),
              actionButton(
                "wrm_info_btn", "",
                icon = icon("info-circle"),
                style = "margin-top: 5px;"
              )
            )
          ),
          
          selectInput("wrm_year", "Select Year:", choices = NULL),
          selectInput("wrm_variable", "Select Variable:", choices = NULL),
          radioButtons("wrm_map_view", "Map View:", 
                       choices = c("Anomaly" = "anomaly", "Annual Mean" = "annual_mean")),
          
          sliderInput(
            "wrm_alpha", "Polygon transparency:",
            min = 0, max = 1, value = 0.8, step = 0.05
          ),
          
          selectInput(
            "wrm_basemap", "Basemap:",
            choices = c(
              "Light" = "CartoDB.Positron",
              "Topographic" = "Esri.WorldTopoMap"
            )
          ),
          
          hr(),
          
          checkboxInput("wrm_show_rm", "Show running mean", TRUE),
          sliderInput(
            "wrm_rm_window", "Running mean (days)",
            min = 0, max = 365, value = 30
          ),
          
          downloadButton("wrm_download_ts", "Download time series CSV"),
          
          helpText("Click a catchment to view its daily time series below.")
        ),
        mainPanel(
          leafletOutput("wrm_map", height = "600px"),
          plotOutput("wrm_timeseries_plot", height = "300px")
        )
      )
    )
  ),
  
  # =======================
  # TAB 3: Future Climate & Hydrology
  # =======================
  tabPanel("Future Climate & Hydrology",
    fluidPage(
      titlePanel("Baluchistan Future Climate & Hydrology"),
      sidebarLayout(
        sidebarPanel(
          fluidRow(
            column(
              10,
              selectInput(
                "cc_scenario", "Scenario:",
                choices = names(cc_scenario_dirs),
                selected = "SSP5-8.5"
              )
            ),
            column(
              2,
              br(),
              actionButton(
                "cc_info_btn", "",
                icon = icon("info-circle"),
                style = "margin-top: 5px;"
              )
            )
          ),
          
          radioButtons(
            "cc_mode", "Display mode:",
            choices = c(
              "Absolute values" = "absolute",
              "Anomaly (future − historical)" = "diff"
            )
          ),
          
          conditionalPanel(
            condition = "input.cc_mode == 'absolute'",
            selectInput(
              "cc_period", "Period:",
              choices = c("2015-2045", "2045-2075", "2070-2100"),
              selected = "2015-2045"
            )
          ),
          
          selectInput(
            "cc_season", "Aggregation:",
            choices = c("annual", "DJF", "MAM", "JJA", "SON"),
            selected = "annual"
          ),
          
          selectInput(
            "cc_variable", "Variable:",
            choices = character(0)
          ),
          
          sliderInput(
            "cc_alpha", "Polygon transparency:",
            min = 0, max = 1, value = 0.8, step = 0.05
          ),
          
          selectInput(
            "cc_basemap", "Basemap:",
            choices = c(
              "Light" = "CartoDB.Positron",
              "Topographic" = "Esri.WorldTopoMap"
            )
          ),
          
          hr(),
          
          checkboxInput("cc_show_rm", "Show running mean", TRUE),
          sliderInput(
            "cc_rm_window", "Running mean (days)",
            min = 0, max = 520, value = 52
          ),
          
          downloadButton("cc_download_ts", "Download time series CSV")
        ),
        
        mainPanel(
          leafletOutput("cc_map", height = "600px"),
          plotOutput("cc_timeseries_plot", height = "300px")
        )
      )
    )
  )
)

# =======================
# SERVER
# =======================

server <- function(input, output, session) {
  
  # =======================
  # CLIMATE FORCING SERVER
  # =======================
  
  # Info modal
  observeEvent(input$cf_info_btn, {
    showModal(
      modalDialog(
        title = "About this application",
        p(
          "This application visualizes mean catchment-scale climate forcing ",
          "variables for the Baluchistan region."
        ),
        p(
          "Maps display long-term mean values for temperature, precipitation, ",
          "radiation, humidity, wind, and potential evapotranspiration."
        ),
        p(
          "Use the variable selector to explore different climate forcing ",
          "parameters across catchments."
        ),
        easyClose = TRUE,
        footer = modalButton("Close")
      )
    )
  })
  
  # Update variable selector with grouped choices
  observe({
    grouped_choices <- split(
      setNames(cf_var_dict$var, cf_var_dict$display_name),
      cf_var_dict$group
    )
    
    updateSelectInput(
      session,
      "cf_selected_var",
      choices = grouped_choices,
      selected = cf_var_dict$var[1]
    )
  })
  
  # Render map
  output$cf_map <- renderLeaflet({
    req(input$cf_selected_var)
    
    # Get variable info from dictionary
    vinfo <- cf_var_dict %>% filter(var == input$cf_selected_var)
    
    # Create color palette
    pal <- colorNumeric(
      palette = vinfo$palette,
      domain = c(vinfo$vmin, vinfo$vmax),
      na.color = "transparent"
    )
    
    leaflet(cf_catchments) %>%
      addProviderTiles(input$cf_basemap) %>%
      addPolygons(
        fillColor = ~pal(get(input$cf_selected_var)),
        fillOpacity = input$cf_alpha,
        color = "#444444",
        weight = 0.5,
        popup = ~paste0(vinfo$display_name, ": ", round(get(input$cf_selected_var), 2))
      ) %>%
      addLegend(
        "bottomright", 
        pal = pal, 
        values = c(vinfo$vmin, vinfo$vmax),
        title = vinfo$display_name,
        opacity = 0.9
      )
  })
  
  # =======================
  # CLIMATE CHANGE SERVER
  # =======================
  
  # Info modal
  observeEvent(input$cc_info_btn, {
    showModal(
      modalDialog(
        title = "About this application",
        p(
          "This application visualizes catchment-scale climate forcing ",
          "and hydrological variables derived from downscaled IPCC ",
          "climate scenarios (SSP1-2.6, SSP2-4.5, SSP5-8.5)."
        ),
        p(
          "Maps show long-term seasonal or annual means, or anomalies ",
          "computed as future minus historical values."
        ),
        p(
          "Click a catchment to display daily time series. ",
          "Linear trends are estimated using ordinary least squares, ",
          "and optional running means can be applied."
        ),
        easyClose = TRUE,
        footer = modalButton("Close")
      )
    )
  })
  
  # Load map data
  cc_gdf <- reactive({
    shp <- cc_get_shp_path(input$cc_scenario, input$cc_mode, input$cc_period, input$cc_season)
    req(file.exists(shp))
    
    st_read(shp, quiet = TRUE) %>%
      mutate(row_id = row_number())
  })
  
  # Variable selector
  observeEvent(cc_gdf(), {
    df <- cc_gdf() %>% st_drop_geometry()
    numeric_vars <- names(df)[sapply(df, is.numeric)]
    physical_vars <- setdiff(numeric_vars, cc_base_fields)
    
    dict_sub <- cc_var_dict %>%
      filter(var %in% physical_vars)
    
    choices <- split(
      setNames(dict_sub$var,
               paste0(dict_sub$label, " (", dict_sub$unit, ")")),
      dict_sub$group
    )
    
    current <- isolate(input$cc_variable)
    if (!current %in% dict_sub$var) current <- dict_sub$var[1]
    
    updateSelectInput(
      session,
      "cc_variable",
      choices = choices,
      selected = current
    )
  })
  
  # Leaflet map
  output$cc_map <- renderLeaflet({
    req(cc_gdf(), input$cc_variable)
    
    data <- cc_gdf()
    vals <- data[[input$cc_variable]]
    vals_clean <- vals[!is.na(vals)]
    
    vinfo <- cc_var_dict %>% filter(var == input$cc_variable)
    
    pal <- if (input$cc_mode == "diff") {
      max_abs <- max(abs(vals_clean))
      colorNumeric(
        palette = "RdBu",
        domain = c(-max_abs, max_abs),
        reverse = TRUE
      )
    } else {
      colorNumeric(
        palette = vinfo$palette,
        domain = c(vinfo$vmin, vinfo$vmax))
    }
    
    leaflet(data) %>%
      addProviderTiles(input$cc_basemap) %>%
      addPolygons(
        fillColor = ~pal(vals),
        fillOpacity = input$cc_alpha,
        color = "black",
        weight = 0.4,
        layerId = ~row_id,
        highlightOptions = highlightOptions(weight = 0)
      ) %>%
      addLegend(
        pal = pal,
        values = vals_clean,
        title = input$cc_variable,
        opacity = 0.9
      )
  })
  
  # Catchment click
  cc_clicked_index <- reactiveVal(NULL)
  
  observeEvent(input$cc_map_shape_click, {
    cc_clicked_index(as.numeric(input$cc_map_shape_click$id))
  })
  
  # Timeseries data
  cc_ts_data <- reactive({
    idx <- cc_clicked_index()
    req(idx, input$cc_variable)
    
    scen_dir <- cc_ts_scenario_dirs[[input$cc_scenario]]
    
    if (input$cc_mode == "absolute") {
      f <- file.path(scen_dir, paste0("catchment_", idx, "_daily_weekly.fst"))
      req(file.exists(f))
      df <- read_fst(f)
    } else {
      f_hist <- file.path(cc_ts_hist_dir, paste0("catchment_", idx, "_daily_weekly.fst"))
      f_fut  <- file.path(scen_dir, paste0("catchment_", idx, "_daily_weekly.fst"))
      
      req(file.exists(f_hist), file.exists(f_fut))
      
      df_hist <- read_fst(f_hist)
      df_fut  <- read_fst(f_fut)
      
      df <- df_fut
      num_cols <- names(df)[sapply(df, is.numeric)]
      df[num_cols] <- df_fut[num_cols] - df_hist[num_cols]
    }
    
    df %>%
      mutate(date = as.Date(week)) %>%
      select(date, all_of(input$cc_variable))
  })
  
  # Timeseries plot
  output$cc_timeseries_plot <- renderPlot({
    df <- cc_ts_data()
    req(nrow(df) > 20)
    
    y <- df[[input$cc_variable]]
    x <- as.numeric(df$date)
    
    fit <- lm(y ~ x)
    slope_yr <- coef(fit)[2] * 365.25
    
    plot(
      df$date, y,
      type = "l",
      col = "grey40",
      xlab = "Date",
      ylab = input$cc_variable,
      main = paste(
        "Catchment", cc_clicked_index(),
        "| Trend:",
        formatC(slope_yr, digits = 3),
        "per year"
      )
    )
    
    if (input$cc_show_rm) {
      rm <- rollmean(y, k = input$cc_rm_window,
                     fill = NA, align = "right")
      lines(df$date, rm, col = "red", lwd = 2)
    }
  })
  
  # Download handler
  output$cc_download_ts <- downloadHandler(
    filename = function() {
      paste0(
        "catchment_", cc_clicked_index(), "_",
        input$cc_scenario, "_",
        input$cc_mode, "_",
        input$cc_variable, ".csv"
      )
    },
    content = function(file) {
      write_csv(cc_ts_data(), file)
    }
  )
  
  # =======================
  # WATER RESOURCES SERVER
  # =======================
  
  # Info modal
  observeEvent(input$wrm_info_btn, {
    showModal(
      modalDialog(
        title = "About this application",
        p(
          "This application visualizes hydrological model outputs for ",
          "catchments in the Baluchistan region."
        ),
        p(
          "Maps show annual mean values or anomalies (deviations from ",
          "long-term means) for various hydrological variables including ",
          "precipitation, snowmelt, discharge, and water balance components."
        ),
        p(
          "Click a catchment to display daily time series data. ",
          "You can toggle between anomaly and annual mean views."
        ),
        easyClose = TRUE,
        footer = modalButton("Close")
      )
    )
  })
  
  # Update dropdowns
  observe({
    updateSelectInput(session, "wrm_year", choices = sort(unique(wrm_anomaly_df$year)))
    
    # Create grouped variable choices
    grouped_choices <- split(
      setNames(wrm_var_dict$display_name, wrm_var_dict$display_name),
      wrm_var_dict$group
    )
    
    updateSelectInput(
      session, 
      "wrm_variable", 
      choices = grouped_choices,
      selected = wrm_var_dict$display_name[1]
    )
  })
  
  # Reactive: Filtered anomaly data
  wrm_filtered_data <- reactive({
    req(input$wrm_year, input$wrm_variable)
    wrm_anomaly_df %>%
      filter(year == input$wrm_year, variable == input$wrm_variable)
  })
  
  # Join with spatial data
  wrm_joined_sf <- reactive({
    left_join(wrm_catchments, wrm_filtered_data(), by = "index")
  })
  
  # Store clicked index
  wrm_clicked_index <- reactiveVal(NULL)
  
  observeEvent(input$wrm_map_shape_click, {
    wrm_clicked_index(as.numeric(input$wrm_map_shape_click$id))
  })
  
  # Render map
  output$wrm_map <- renderLeaflet({
    req(wrm_joined_sf(), input$wrm_map_view)
    data <- wrm_joined_sf()
    
    column_to_plot <- input$wrm_map_view
    values <- data[[column_to_plot]]
    
    if (column_to_plot == "anomaly") {
      max_abs <- max(abs(values), na.rm = TRUE)
      color_range <- c(-max_abs, max_abs)
      pal <- colorNumeric(palette = brewer.pal(11, "RdBu"), domain = color_range, na.color = "transparent")
    } else {
      color_range <- range(values, na.rm = TRUE)
      pal <- colorNumeric(palette = rev("viridis"), domain = color_range, na.color = "transparent")
    }
    
    leaflet(data) %>%
      addProviderTiles(input$wrm_basemap) %>%
      addPolygons(
        fillColor = ~pal(values),
        fillOpacity = input$wrm_alpha,
        color = "black",
        weight = 0.5,
        layerId = ~index,
        label = ~paste0("Index: ", index, "<br>", column_to_plot, ": ", round(values, 3)),
        highlightOptions = highlightOptions(weight = 2, color = "#666", fillOpacity = 0.9, bringToFront = TRUE)
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = color_range,
        title = paste(column_to_plot, "<br>", input$wrm_variable, input$wrm_year),
        labFormat = labelFormat(digits = 2)
      )
  })
  
  # Time series plot
  output$wrm_timeseries_plot <- renderPlot({
    req(wrm_clicked_index(), input$wrm_variable)
    
    idx <- wrm_clicked_index()
    var <- input$wrm_variable
    
    display_to_original <- setNames(names(wrm_variable_names), wrm_variable_names)
    var_original <- display_to_original[[var]]
    
    if (is.null(var_original)) {
      plot.new()
      title(main = paste("Unknown variable:", var))
      return()
    }
    
    file_path <- paste0("./data/hydrology/results/result_", idx, ".csv")
    if (!file.exists(file_path)) {
      plot.new()
      title(main = paste("File not found:", file_path))
      return()
    }
    
    ts_data <- read_csv(file_path, show_col_types = FALSE)
    
    if (!("Date" %in% names(ts_data))) {
      plot.new()
      title(main = "No 'Date' column found in file.")
      return()
    }
    
    ts_data <- ts_data %>% mutate(date = as.Date(Date))
    
    if (!(var_original %in% names(ts_data))) {
      plot.new()
      title(main = paste("Variable", var_original, "not found in file."))
      return()
    }
    
    # Plot with running mean and trend
    y <- ts_data[[var_original]]
    x <- as.numeric(ts_data$date)
    
    # Calculate trend
    fit <- lm(y ~ x)
    slope_yr <- coef(fit)[2] * 365.25
    
    # Base plot
    plot(
      ts_data$date, y,
      type = "l",
      col = "grey40",
      xlab = "Date",
      ylab = var,
      main = paste(
        "Catchment", idx,
        "| Trend:",
        formatC(slope_yr, digits = 3),
        "per year"
      )
    )
    
    # Add running mean if enabled
    if (input$wrm_show_rm && input$wrm_rm_window > 1) {
      rm <- rollmean(y, k = input$wrm_rm_window,
                     fill = NA, align = "right")
      lines(ts_data$date, rm, col = "red", lwd = 2)
    }
  })
  
  # Download handler
  output$wrm_download_ts <- downloadHandler(
    filename = function() {
      idx <- wrm_clicked_index()
      var <- input$wrm_variable
      paste0(
        "catchment_", idx, "_",
        input$wrm_year, "_",
        gsub(" ", "_", var), ".csv"
      )
    },
    content = function(file) {
      req(wrm_clicked_index(), input$wrm_variable)
      
      idx <- wrm_clicked_index()
      var <- input$wrm_variable
      display_to_original <- setNames(names(wrm_variable_names), wrm_variable_names)
      var_original <- display_to_original[[var]]
      
      file_path <- paste0("./data/hydrology/results/result_", idx, ".csv")
      if (file.exists(file_path)) {
        ts_data <- read_csv(file_path, show_col_types = FALSE) %>%
          mutate(date = as.Date(Date))
        write_csv(ts_data, file)
      }
    }
  )
}

# Run the app
shinyApp(ui, server)
