# for_heatmap.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![needs](https://img.shields.io/badge/needs-workspace%20variables-orange)

Extracts the **time series of selected FBRs** from a small cropped IRM region for heat-map / surface plotting.

## What it does

1. Loads the `.tif` frames from the folder in `f` and crops a fixed 12 × 12 px window (`xstart = 60`, `ystart = 296`).
2. Converts intensity with `(A − Inmin) / conv` (`Inmin = 902.96698`, `conv = 34.08807`).
3. For each region in `FBR` (rows `[row col …]`) cuts the corresponding `M × N` block into `AAA`.
4. Keeps the blocks listed in `val` (`AAA_new`) and flattens them into `AAA_tot`.
5. Saves `010.mat` (`AAA_new`, `FBR`, `val`, `AAA_tot`).
6. Plots a surface of frame 20 and the time trace of pixel (1,1) with a 0.05 s frame interval.

## Variables that must already exist in the workspace

| Variable | Meaning |
|---|---|
| `FBR` | Region list from [`Multifol_findFBRnew.m`](README_Multifol_findFBRnew.md) |
| `val` | Indices of the regions to keep |
| `M`, `N` | Region height and width (12) |

## Usage

1. Load the matching `AAAna*.mat` / `BAAAna*.mat` file so `FBR`, `M`, `N` exist, and define `val`.
2. Edit the folder in `f`, the crop coordinates and calibration constants.
3. Run the script.

## Notes

- The output name `010.mat` is hard-coded; change it per cell.
- Hard-coded Windows path (`G:\IRM\...`).
