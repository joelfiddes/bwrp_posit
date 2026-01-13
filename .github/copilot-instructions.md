# Baluchistan Water Resources Project (BWRP) - AI Coding Guide

## Project Overview

This workspace contains three R Shiny applications for visualizing climate and hydrological data for the Baluchistan region:

1. **bwrp_app**: Climate forcing explorer (mean catchment-level climate variables)
2. **bwrp_climatechange**: Climate change atlas (IPCC scenarios with anomaly analysis)
3. **bwrp_wrm_app**: Water resources atlas (hydrological model outputs with time series)

All apps are deployed to Posit Connect Cloud and use the Leaflet mapping library for interactive spatial visualization.

## Architecture & Data Flow

### Application Structure Pattern
Each Shiny app follows a consistent pattern:
- Single `app.R` file containing UI, server, and data loading
- Spatial data stored as Shapefiles (`.shp`, `.dbf`, `.cpg`, `.prj`, `.shx`)
- Tabular data in CSV format (climate/hydrological variables)
- `manifest.json` for dependency management (generated via `rsconnect::writeManifest()`)

### Data Organization

**bwrp_climatechange** has the most complex data structure:
- `data_hist/`, `data_ssp126/`, `data_ssp245/`, `data_ssp585/`: Climate averages by catchment
- `data_fst_weekly/`: Time series data in `.fst` format for performance
- `by_period/`: Aggregated shapefiles (2015-2045, 2045-2075, 2070-2100) × (annual, DJF, MAM, JJA, SON)
- Anomaly mode: computes future minus historical differences

**bwrp_wrm_app**: 
- `inputs/`: Shapefile and aggregated anomaly CSV
- `results/`: Daily time series per catchment (`result_<index>.csv`)

### Spatial-Temporal Linking
- Catchments indexed by `row_id` or `index` field
- Click interaction: `input$map_shape_click$id` retrieves catchment index
- Time series files named by catchment index (e.g., `catchment_42_daily_weekly.fst`)

## Critical Developer Workflows

### Deployment to Posit Connect
```r
# In app directory, start R session:
rsconnect::writeManifest()  # Generates/updates manifest.json
# Then deploy via Posit Connect UI at https://connect.posit.cloud/
```

### Running Locally
```bash
cd bwrp_app  # or bwrp_climatechange, bwrp_wrm_app
R
# In R console:
shiny::runApp()
```

### Variable Dictionary Pattern (bwrp_climatechange)
The app uses a grouped variable dictionary (`var_dict` tibble) to:
- Organize variables by physical category (Temperature, Precipitation, etc.)
- Define color palette and scale ranges per variable
- Generate hierarchical dropdowns (grouped by category)

Example structure:
```r
var_dict <- tibble::tribble(
  ~var, ~label, ~unit, ~group, ~vmin, ~vmax, ~palette,
  "Tair_C", "Air temperature", "°C", "Temperature", 4, 40, "inferno"
)
```

## Project-Specific Conventions

### Color Palette Selection
- **Diverging (anomaly mode)**: Use `"RdBu"` with symmetric limits (`max_abs`)
- **Sequential (absolute mode)**: Use variable-specific palette from `var_dict` (e.g., `"viridis"`, `"inferno"`)

### Reactivity & Performance
- Use `req()` to ensure inputs exist before rendering
- Shapefiles loaded reactively based on scenario/period/season selection
- FST format used for large time series (faster than CSV)
- `isolate()` used to prevent variable dropdown from changing on map data reload

### Naming Conventions
- Climate scenarios: `"SSP1-2.6"`, `"SSP2-4.5"`, `"SSP5-8.5"` (user-facing labels)
- Internal directories: `ssp126`, `ssp245`, `ssp585` (lowercase, no dots)
- Variable names: Match original data exactly (e.g., `TP_mmhr` not `total_precip`)

### Coordinate Reference System
- All spatial data use WGS84 (EPSG:4326)
- Geometry stored as WKT in CSV files for `bwrp_app`
- Use `st_read(..., quiet = TRUE)` to suppress shapefile warnings

## Integration Points & Dependencies

### R Package Ecosystem
Core dependencies (check `manifest.json` for full list):
- `shiny`: UI framework
- `sf`: Spatial data handling
- `leaflet`: Interactive maps
- `dplyr`, `tidyr`: Data manipulation
- `fst`: Fast serialization for time series
- `zoo`: Running mean calculations (`rollmean()`)

### External Data Sources
- Climate forcing data appears to be pre-computed (not generated in apps)
- Shapefile structure: HydroBASINS-style with hierarchical basin IDs (`HYBAS_ID`, `NEXT_DOWN`)

### Cross-App Patterns
Variable recoding for display (bwrp_wrm_app):
```r
variable_names <- c(
  Prain = "Rainfall (mm)",
  q_sim = "Simulated Discharge (m³/s)"
)
# Display name → internal name lookup for file reading
display_to_original <- setNames(names(variable_names), variable_names)
```

## Common Gotchas

1. **Shapefile path construction**: Use `file.path()` with `by_period_subdir` - don't hardcode paths
2. **Variable existence**: Always check `var %in% names(ts_data)` before plotting
3. **Date conversion**: FST stores dates as strings; use `as.Date(week)` for plotting
4. **Polygon transparency**: Controlled via `input$alpha` slider (0-1 range)
5. **Running mean edge effects**: `rollmean(..., fill = NA, align = "right")` leaves leading NAs

## Testing & Debugging

- Click events logged via `print(input$map_shape_click)` in server
- File existence checked with `req(file.exists(path))` before loading
- Use `st_drop_geometry()` to inspect attribute data without spatial complexity
- Basemap options: `"CartoDB.Positron"` (light), `"Esri.WorldTopoMap"` (terrain)

## License
GNU General Public License v3.0 (see LICENSE files in each app directory)
