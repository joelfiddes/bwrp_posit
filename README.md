# BWRP Combined Dashboard

This is a unified dashboard combining all three BWRP Shiny applications into a single interface with navigation tabs.

## Overview

The BWRP Combined Dashboard integrates:

1. **Climate Forcing Explorer** - Mean catchment-level climate variables
2. **Climate Change Atlas** - IPCC climate scenarios (SSP1-2.6, SSP2-4.5, SSP5-8.5) with anomaly analysis
3. **Water Resources Atlas** - Hydrological model outputs with time series analysis

## Features

- **Tabbed Navigation**: Easy switching between different visualization modes
- **Consistent Interface**: Familiar controls from original apps preserved
- **Shared Resources**: Single deployment with all data accessible from one location
- **Interactive Maps**: Leaflet-based visualization across all tabs
- **Time Series Analysis**: Click catchments to view detailed temporal data (Climate Change & Water Resources tabs)

## Running Locally

```bash
cd bwrp_combined
R
# In R console:
shiny::runApp()
```

Or from command line:
```bash
R -e "shiny::runApp('/Users/joel/src/bwrp/bwrp_combined')"
```

## Dependencies

Required R packages:
- `shiny`
- `sf` (spatial features)
- `leaflet` (interactive maps)
- `dplyr`, `tidyr` (data manipulation)
- `readr` (CSV reading)
- `ggplot2` (plotting)
- `viridisLite`, `RColorBrewer` (color palettes)
- `zoo` (time series)
- `fst` (fast data serialization)
- `tibble` (data frames)

## Data Structure

The combined app references data from the three original app directories:
- `../bwrp_app/` - Climate forcing data
- `../bwrp_climatechange/` - Climate change scenarios and time series
- `../bwrp_wrm_app/` - Water resources model outputs

**Note**: Keep the original app directories intact as this app reads data from them.

## Deployment

To deploy to Posit Connect Cloud:

```r
# In app directory:
rsconnect::writeManifest()
# Then deploy via Posit Connect UI
```

## Navigation

### Tab 1: Climate Forcing Explorer
- Select climate forcing variables (temperature, precipitation, radiation, etc.)
- View spatial distribution across catchments
- Static map view with popup information

### Tab 2: Climate Change Atlas
- Choose IPCC scenarios (SSP1-2.6, SSP2-4.5, SSP5-8.5)
- Toggle between absolute values and anomalies
- Select time periods and seasonal aggregations
- Click catchments to view time series with trend analysis
- Customize visualization with transparency and basemap options
- Download time series data

### Tab 3: Water Resources Atlas
- Select year and hydrological variable
- Toggle between anomaly and annual mean views
- Click catchments to view daily time series
- Analyze water balance components and discharge

## License

GNU General Public License v3.0
