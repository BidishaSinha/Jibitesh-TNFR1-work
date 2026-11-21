# flip_tr_m_cherry_final_peak_local_analysis.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![interactive](https://img.shields.io/badge/mode-interactive-orange) ![stage](https://img.shields.io/badge/analysis-FLIPTR%20lifetime-lightgrey)

Analyses **FLIPTR lifetime** together with **TNFR1-mCherry** images from a single cell. It does two things:

1. A **whole-cell local analysis** on a grid of 5 × 5 px ROIs (mean lifetime vs mCherry intensity).
2. A **cluster analysis**: manually selected mCherry clusters are localised by their brightest pixel, measured in a 10 × 10 px ROI, and profiled with line scans to give population-averaged lifetime and intensity profiles.

## Required inputs

Three images of the **same field of view** (OME-TIFF), set at the top of the script:

| Variable | Image | Used for |
|---|---|---|
| `flip_tr_path` | `... - eGFP lifetime.ome.tiff` | FLIPTR lifetime channel |
| `mcherry_lt_path` | `... - mCherry lifetime.ome.tiff` | Background threshold and pixel mask for the mCherry image |
| `mcherry_path` | `... - mCherry.ome.tiff` | TNFR1 intensity, used to find clusters |

The "eGFP lifetime" file is treated as the FLIPTR lifetime image.

## Requirements

- MATLAB R2019a or newer (uses `drawfreehand`, `drawrectangle` and the `Circularity` property of `regionprops`)
- Image Processing Toolbox (`imread`, `regionprops`, `improfile`, `imshow`, `questdlg`, `ginput`)
- No other scripts from this repository are needed. The helper `extractClusterROIs` is defined at the bottom of the file.

## Usage

1. Set the three file paths at the top of the script.
2. Adjust `lowerThreshold` / `upperThreshold` (cluster area limits in pixels; defaults **10** and **1000**).
3. Run the script from the folder where the results should be saved.
4. Follow the prompts:
   1. **Draw the cell boundary** with the freehand tool; answer "Redraw mask?" until satisfied.
   2. **Draw a background rectangle** (it is forced to a square); keep or redraw it.
   3. **Click the clusters to keep** in the yellow-on-blue map. Selected clusters turn red; click again to deselect; press **Enter** to finish.

## What it does

| Step | Description |
|---|---|
| Thresholding | The mean value inside the background square is the threshold for the FLIPTR lifetime image and for the mCherry lifetime image. Pixels above threshold **and** inside the cell mask are kept. |
| Normalised images | `fliptr_img_norm` holds FLIPTR lifetime at the kept pixels. `mcherry_img_norm` holds mCherry intensity at the pixels kept by the mCherry-lifetime threshold. |
| Whole-cell local analysis | Non-overlapping 5 × 5 px ROIs lying entirely inside the cell. Only pixels with non-zero FLIPTR lifetime are averaged. Saved as `LocalTable`. |
| Cluster detection | Connected components of `mcherry_img_norm > 0` with area between `lowerThreshold` and `upperThreshold`. |
| Peak localisation | Each cluster centre is its **brightest mCherry pixel**, not the centroid. |
| Manual selection | Only clusters you click are kept for all later steps. |
| Cluster ROIs | A 10 × 10 px ROI around each peak is cut from the raw FLIPTR and mCherry images and averaged (`ROI_FLIPTR`, `ROI_mCherry`). |
| Line scans | Along the cluster **major axis** (50 points, nearest-neighbour), plus **x** and **y** scans through the peak (15 points each, half-length 7 px, bilinear). |
| Population profiles | Mean ± SEM across clusters, plotted with FLIPTR on the left axis and mCherry on the right axis. The x + y scan is mirrored about its first 8 points to give a symmetric 15-point profile. |

## Outputs

Written to the current folder, using fixed file names.

| File | Content |
|---|---|
| `ClusterResults.csv` | One row per selected cluster |
| `WholeCell_5x5_LocalAnalysis.csv` | One row per 5 × 5 ROI |
| `lifetime_info.mat` | `LocalTable`, `Results`, `rois_fliptr`, `rois_mcherry`, and all line-scan matrices (`lt_scan_*`, `*_x`, `*_y`, `*_xy`) |

**`Results` columns:** `ClusterID, PeakX, PeakY, ClusterArea, Circularity, MajorAxis, MinorAxis, ROI_mCherry, ROI_FLIPTR, ClusterMean_mCherry, ClusterMean_FLIPTR`

**`LocalTable` columns:** `CenterX, CenterY, MeanLifetime, StdLifetime, MeanMCherry, StdMCherry, IntegratedMCherry`

## Adjustable parameters

| Parameter | Default | Meaning |
|---|---|---|
| `lowerThreshold`, `upperThreshold` | 10, 1000 | Cluster area limits (px) |
| `roiSize_local` | 5 | Whole-cell ROI size (px) |
| `roiSize` | 10 | Cluster ROI size (px); also hard-coded as 10 inside `extractClusterROIs` |
| `line_scan_length` | 50 | Points in the major-axis scan |
| `half_len` | 7 | Half-length of the x / y scans (px) |
| Display range `[1e-10 20e-10]` | – | Contrast used only for drawing the cell and background; change it for your intensity scale |

## Notes and known issues

- **Output names are fixed**, so running the script again in the same folder overwrites the previous results. Run each cell in its own folder, or rename the outputs.
- If you choose **Redraw** for the background ROI, the script calls `delete(square_plot)`, a variable that is never defined, and stops with an error. Remove that line, or choose **Keep** and redraw by restarting.
- Clusters whose 10 × 10 ROI would cross the image edge are skipped with a warning, but their ROI is left as zeros, so their `ROI_*` means come out as 0. Exclude those rows before analysis.
- Selecting no clusters will make the later steps fail; select at least one.
- Variables named `mean_cluster_lt` / `ClusterMean_mCherry` hold mean mCherry **intensity** of the cluster, not lifetime.
- The "radial" profile is the sum of the x and y scans, not their average, and the plot labelled "standard deviation" actually shows SEM (`std / sqrt(n)`).
- Paths are Windows paths (`H:\...`); the file name contains spaces, so keep the quotes.
- `readme.docx` in your older FLIPTR data folder describes an earlier version (watershed segmentation, minimum-distance overlap removal, `lowerThreshold = 4`). Those steps are **not** in this script.
