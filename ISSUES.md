# Known Issues

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
