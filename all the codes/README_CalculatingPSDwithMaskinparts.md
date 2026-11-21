# CalculatingPSDwithMaskinparts.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![stage](https://img.shields.io/badge/stage-1%20PSD-lightgrey)

Interactive driver that masks a cell and a background region on an IRM time series and computes **per-pixel power spectral densities (PSD)** for both.

## What it does

1. Reads the first and last `.tif` frames of the folder in `d_name` and sums them for display.
2. Asks you to draw the **cell boundary** (`imfreehand`) and a **background ROI** (`imrect`).
3. Creates `<d_name>\pcov\` and saves both masks to `pcov\BW.mat` (`BW`, `BWbck`).
4. Calls `psdIMcovMaskpixelreadJG1024Long` twice – once on the cell mask (`'cell'`) and once on the background mask (`'Backg'`) – with `sps = 20`, `cf = 42.58174`, `order = 32`.

## Files needed

| File | Role |
|---|---|
| `psdIMcovMaskpixelreadJG1024Long.m` | Does the PSD computation (must be on the MATLAB path) |
| IRM `.tif` stack in `d_name` | Input frames, number of frames a multiple of 2048 |

## Requirements

MATLAB, Image Processing Toolbox (`imfreehand`, `imrect`), Signal Processing Toolbox (via the called function).

## Usage

1. Edit the input at the top of the script (use **single quotes**):
   ```matlab
   d_name = 'L:\...\Exported\002\set';
   ```
2. Adjust `sps` (sampling rate, Hz), `cf` (intensity→height conversion factor) and `order` (AR model order) if your acquisition differs.
3. Run the script and draw the two ROIs when prompted.

## Outputs

In `<d_name>\pcov\`:

- `BW.mat` – cell mask and background mask
- `allpsd3_cell_<id>_<rep>.mat` and `allpsd3_Backg_<id>_<rep>.mat` – per-pixel PSD cubes
- `allpsd2X.dat` – frequency axis

## Notes

- Paths use Windows backslashes; change them for macOS/Linux.
- The script contains the commented parameter `rem1 = 'cell'` – keep it as a character vector, not a string.
- Next step: [`Multifol_findFBRnew.m`](README_Multifol_findFBRnew.md).
