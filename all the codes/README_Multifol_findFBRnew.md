# Multifol_findFBRnew.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![interactive](https://img.shields.io/badge/mode-interactive-orange)

End-to-end script that, for several folders and repeats, (1) draws cell/nucleus masks and detects **fluctuation regions (FBRs)**, computes temporal/spatial standard deviations, and (2) fits each region's PSD to obtain **membrane tension**.

## Workflow

**Part 1 – region detection** (one pass per folder/repeat/cell)

1. Dialogs ask for the number of folders and the number of repeats; you pick the folders.
2. For each cell you draw an outer rectangle, the cell boundary (`imfreehand`) and the nucleus.
3. Max/min projections are thresholded to build a mask; every **12 × 12 px** window (`M = N = 12`) lying fully inside the valid area is recorded in `FBR`.
4. For each FBR: `SDt` (temporal SD map, mean/median/SD) and `SDs` (spatial SD averaged over 20 frames).
5. Saved as `AAAna<name>Cell_<nn>.mat`.

**Part 2 – PSD fitting** (run after selecting the `.mat` files from Part 1 in the file dialog)

1. Loads the cell PSD (`allpsd3_cell_*.mat`), the background PSD (`allpsd3_Backg_*.mat`) and the frequency file (`allpsd2X.dat`) produced by the PSD step; uses frequency bins 2–91.
2. Averages the PSD in each FBR, subtracts the background and `0.2`.
3. Fits with [`fitPSD.m`](README_fitPSD.md).
4. Keeps FBRs with **R² > 0.999, tension > 0.05, Ac < 9.5**.
5. Saves `B<filename>.mat` with `fbrTen`, `fbrRS`, `fbrV`, `fbrAc`, `fbrC`, `FBR`, `SDt`, `SDs`, masks and file paths.

## Files needed

| File | Role |
|---|---|
| `fitPSD.m`, `psdsimfunc6.m` | PSD fitting |
| `<folder>\set\*.tif` | IRM frames |
| `<folder>\set\pcov\allpsd3_cell_*.mat`, `allpsd3_Backg_*.mat`, `allpsd2X.dat` | Output of [`CalculatingPSDwithMaskinparts.m`](README_CalculatingPSDwithMaskinparts.md) |

## Requirements

MATLAB with Image Processing and Curve Fitting Toolboxes.

## Usage

1. Set `dirname` (start folder of the picker) and, if needed, the calibration constants `Inmin` and `conv` near the top.
2. Run the script; answer the dialogs and draw the ROIs.
3. When the file dialog opens for Part 2, select all `AAAna*.mat` files.

## Outputs

- `AAAna<name>Cell_<nn>.mat` – regions and SD maps
- `BAAAna<name>Cell_<nn>.mat` – fitted tension and quality-filtered regions

## Notes

- `loadten = 'n'` forces a fresh fit; leave it as is.
- `Inmin` is reassigned to the minimum image intensity inside the loop, so it differs from the initial calibration value for later cells – check this if you process many cells in one run.
- Next steps: [`follow_ccp_jibitesh_ver8_stuckpuncta.m`](README_follow_ccp_jibitesh_ver8_stuckpuncta.md), [`concat_param.m`](README_concat_param.md), [`plot_FBRwisetension_colate_matrix_grey.m`](README_plot_FBRwisetension_colate_matrix_grey.md).
