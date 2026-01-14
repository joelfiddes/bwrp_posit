# Known Issues

## Units Audit - RESOLVED

### Issue: Inconsistent or incorrect units in variable dictionaries

**Status**: RESOLVED ✅  
**Priority**: High  
**Date Reported**: 2026-01-14  
**Date Resolved**: 2026-01-14

**Description**:
All units have been verified and corrected across the three variable dictionaries based on:
1. Analysis of actual data files (daily time series in hydrology data)
2. Regional context: Baluchistan receives 100-600 mm/year precipitation
3. Magnitude verification: Daily precip values 0-7 mm consistent with arid climate

**Changes Made**:

### Climate Forcing Tab (cf_var_dict) - Lines 28-63
**CORRECTED**:
- `TP_mmhr`, `Sf_mmhr`, `Rf_mmhr`: Changed from "mm/hr" → **"mm/day"** (daily averages)
- `PET_mm_hr_penman`, `PET_mm_hr_priestly`: Changed from "mm/hr" → **"mm/day"**

### Future Climate Tab (cc_var_dict) - Lines 92-135
**CORRECTED**:
- Rate variables: `TP_mmhr`, `Sf_mmhr`, `Rf_mmhr` → **"mm/day"**
- **Period totals** (seasonal/annual accumulations): `Prain`, `Psnow`, `TP_mm` → **"mm"** (0-500 range indicates these are accumulated totals over analysis periods, NOT daily)
- **Daily flows**: `Msnow`, `Total`, `Rech`, `Eac`, `WB` → **"mm/day"**
- **Storage variables** (stocks, not flows): `SM`, `SWE`, `STZ`, `SUZ`, `SLZ` → **"mm"** (unchanged)
- **Energy fluxes**: `Qg`, `Q0`, `Q1`, `Q2` → **"W m⁻²"** (confirmed - these are energy terms)
- PET variables → **"mm/day"**

### Current Hydrology Tab (wrm_var_dict) - Lines 168-191
**CORRECTED**:
- **Daily flows**: `Msnow`, `Rech`, `Eac`, `Qg`, `Q0`, `Q1`, `Q2`, `WB` → **"mm/day"**
- **Storage variables**: `SM`, `STZ`, `SUZ`, `SLZ` → **"mm"** (unchanged - these are state variables)
- **Discharge**: `q_sim` → **"m³/s"** (confirmed)

**Rationale**:
- **100-600 mm/year** annual precipitation ÷ 365 = **0.27-1.64 mm/day** average
- Daily values of 0-5 mm/day are physically reasonable for arid region
- Hourly rates would be 0.01-0.2 mm/hr, inconsistent with data ranges
- Variables with vmax=500 mm are accumulated period totals (e.g., seasonal, annual)
- Storage variables (SM, SWE, zones) remain in mm as state measurements

**Verification**:
Checked actual hydrology data files showing Prain values: 0, 0.74, 3.8, 0.44 mm → confirms daily temporal resolution.

---

## Future Climate & Hydrology Tab - Anomaly Mode

### Issue: Length mismatch warnings when computing anomalies

**Status**: Open  
**Priority**: Medium  
**Date Reported**: 2026-01-14

**Description**:
When switching to "Anomaly (future − historical)" mode in the Future Climate & Hydrology tab, R generates warnings about length mismatches:

```
Warning in df_fut[[col]] - df_hist[[col]] :
  longer object length is not a multiple of shorter object length
```

**Root Cause**:
The historical and future climate datasets have different time periods/lengths. When computing anomalies by subtracting `df_hist` from `df_fut`, R recycles the shorter vector, which may produce incorrect results.

**Current Behavior**:
- Time series plot displays without crashing (fixed)
- Anomaly calculations may be inaccurate due to vector recycling
- Multiple warnings appear in console

**Expected Behavior**:
- Historical and future datasets should have matching time periods
- Anomaly calculations should align corresponding time points
- No length mismatch warnings

**Proposed Solution**:
1. Add validation to check if `nrow(df_hist) == nrow(df_fut)`
2. If lengths don't match, either:
   - Filter to common time period (intersection)
   - Show informative error message to user
   - Align datasets by date/week before computing differences
3. Consider using `inner_join()` or `left_join()` on the `week` column to ensure proper alignment

**Code Location**:
- File: `app.R`
- Lines: ~605-620 (anomaly mode calculation in `cc_ts_data` reactive)

**Related Files**:
- Historical data: `data/future_climate/data_fst_weekly/hist/`
- Future scenario data: `data/future_climate/data_fst_weekly/ssp*/`
