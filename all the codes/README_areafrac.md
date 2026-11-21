# areafrac.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![interactive](https://img.shields.io/badge/mode-uses%20imtool-orange)

Quantifies **TIRF puncta** inside a cell outlined by an ImageJ ROI: number density, area fraction, mean intensity, spacing and circularity.

## What it does

1. Reads a TIRF image and removes background with a Gaussian blur (σ = 10 px) subtraction, then normalises (`mat2gray`).
2. Thresholds at `0.03` (`im2bw` – change this value per dataset).
3. Reads the cell outline from an ImageJ `.roi` file via [`ReadImageJROI.m`](README_ReadImageJROI.md) and builds a mask with `roipoly`.
4. Keeps only puncta inside the mask, cleans with 1-px erosion + dilation, then runs `regionprops`.
5. Computes with a **pixel size of 0.065 µm**:

| Variable | Meaning |
|---|---|
| `Total_area_of_cell` | Cell area in µm² |
| `Number_density` | Puncta per µm² |
| `Area_density` | Puncta pixels / cell pixels |
| `allIntensities` | Mean intensity of each punctum |
| `Av_dist_um` | Mean pairwise centroid distance (µm) |
| `Min_av_dis` | Mean nearest-neighbour distance (µm), via `min_dist` |
| `Median_circularity` | Median puncta circularity |

## Files needed

| File | Role |
|---|---|
| `ReadImageJROI.m` | Reads the `.roi` file |
| **`min_dist.m`** | Nearest-neighbour helper – **not included in this repository; add it** |
| TIRF image (`.tif`) and ImageJ ROI (`.roi`) | Inputs |
| Image Processing + Statistics Toolboxes | `regionprops`, `pdist` |

## Usage

Edit the hard-coded image path, ROI path and the output names (`c38.mat`, `c38.txt`) near the top, then run. The script opens several `imtool` windows for inspection.

## Outputs

- `c38.mat` – whole workspace
- `c38.txt` – tab-separated table of the retained puncta (area, centroid x, centroid y, circularity)
- Values printed to the command window

## Notes

`im2bw` is deprecated in recent MATLAB releases; `imbinarize` is the replacement.
