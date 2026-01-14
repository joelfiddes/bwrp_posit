# Known Issues

## Units Audit Required

### Issue: Inconsistent or incorrect units in variable dictionaries

**Status**: Open  
**Priority**: High  
**Date Reported**: 2026-01-14

**Description**:
Need to verify all units across the three variable dictionaries are accurate and consistent with the actual data.

**Specific Issues Identified**:

### Climate Forcing Tab (cf_var_dict)
- `TP_mmhr`: "mm/hr" - **Likely should be "mm/day"** if these are daily averages
- `Sf_mmhr`: "mm/hr" - **Likely should be "mm/day"**
- `Rf_mmhr`: "mm/hr" - **Likely should be "mm/day"**
- `PET_mm_hr_penman`: "mm/hr" - **Check if daily or hourly**
- `PET_mm_hr_priestly`: "mm/hr" - **Check if daily or hourly**

### Future Climate Tab (cc_var_dict)
- `TP_mmhr`: "mm/hr" - **Likely should be "mm/day"**
- `Sf_mmhr`: "mm/hr" - **Likely should be "mm/day"**
- `Rf_mmhr`: "mm/hr" - **Likely should be "mm/day"**
- `Prain`: "mm" - **Needs clarification: mm/day? mm/week? mm/year?**
- `Psnow`: "mm" - **Needs clarification**
- `TP_mm`: "mm" - **Needs clarification**
- `Msnow`: "mm" - **Needs clarification: mm/day? mm/week?**
- `Total`: "mm" - **Needs clarification**
- `Rech`: "mm" - **Needs clarification**
- `Eac`: "mm" - **Needs clarification**
- `SM`: "mm" - **Needs clarification**
- `WB`: "mm" - **Needs clarification**
- `SWE`: "mm" - **Needs clarification**
- `STZ`, `SUZ`, `SLZ`: "mm" - **Needs clarification**
- `Qg`, `Q0`, `Q1`, `Q2`: Listed under "Hydrology" but units are "W m⁻²" - **Energy fluxes or water fluxes?**
- `PET_mm_hr_penman`: "mm/hr" - **Check if daily or hourly**
- `PET_mm_hr_priestly`: "mm/hr" - **Check if daily or hourly**

### Current Hydrology Tab (wrm_var_dict)
- `Prain`: "mm" - **Needs clarification: mm/day?**
- `Psnow`: "mm" - **Needs clarification: mm/day?**
- `Total`: "mm" - **Needs clarification: mm/day?**
- `SWE`: "mm" - **Needs clarification**
- `Msnow`: "mm" - **Needs clarification: mm/day?**
- `Rech`: "mm" - **Needs clarification: mm/day?**
- `Eac`: "mm" - **Needs clarification: mm/day?**
- `SM`: "mm" - **Needs clarification**
- `Qg`, `Q0`, `Q1`, `Q2`: "mm" - **Needs clarification: mm/day?**
- `WB`: "mm" - **Needs clarification: mm/day?**
- `STZ`, `SUZ`, `SLZ`: "mm" - **Needs clarification**

**Action Items**:
1. Check original data source documentation for correct units
2. Verify temporal resolution (hourly, daily, weekly, annual)
3. Update all three variable dictionaries with correct units
4. Ensure units are consistent between tabs where same variables appear
5. Consider adding temporal context to accumulation variables (e.g., "mm/day" vs "mm/week")

**Code Locations**:
- Lines 28-63: `cf_var_dict` (Climate Forcing)
- Lines 92-135: `cc_var_dict` (Future Climate)
- Lines 168-191: `wrm_var_dict` (Current Hydrology)

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
