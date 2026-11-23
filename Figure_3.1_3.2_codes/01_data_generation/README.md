# 01 — Data generation (MATLAB)

Turns the raw IRM + TIRF acquisitions into one results file per run:
`Curvature_Analysis_Output_<timestamp>/AllCells_CurvatureTopology_TimeSeries.mat` (variable `Allstats`: one struct per
detected TNFR1 cluster) plus CSV/PNG summaries. All files here are **unmodified copies** of the originals in `~/Downloads`.

## Files
| File | Role |
|---|---|
| `jibitesh_irmtirf_complete_platewise_samecell.m` | Main pipeline for the **control** data (`with_good_cells/set5…7`, plates looped inside the script). |
| `jibitesh_irmtirf_complete_platewise_samecell_tnfa.m` | Same pipeline for the **TNFα-added** data (`For TNFa/set1–2`). Differences from the control file: data root, `Before_After/002` snapshots (`002.tif` before, `004.tif` after), IRM movie taken from the 6th numeric sub-folder (`d(6)`) instead of the 1st, BAAA file read from `folder2`. |
| `objDetectandRegionprops.m` | Cluster detection on a TIRF snapshot: adaptive threshold (`adaptthresh` / `imbinarize`, parameters set in the pipeline: `sensitivity=0.25, ThreshA=10, ThreshB=5000, thresh=200`), restricted to the IRM-derived mask, then `regionprops` (area, circularity, eccentricity, intensity, centroid `XC/YC`, pixel lists). |
| `curvature5x5_cubicFit.m` | Per-patch curvature: cubic surface fit to a 5×5 patch → mean/Gaussian/principal curvature, curvedness, shape index, class. |
| `addFBR_values_to_objects.m` | Looks up FBR SD / SDt / tension for each cluster (and random point) from the BAAA maps (overlapping FBRs). |
| `collateCurvatureStats_fromAllstats_outall.m` | Collates per-cluster results into the CSV tables. |
| `plotClasswiseStatistics.m`, `plotCurvatureCorrelations.m` | Class-wise statistics and correlation figures written at the end of a run. |
| `upstream/Multifol_findFBRnew.m` | FBR / SD / SDtime / tension analysis script stored next to the data; probably produced the `BAAA*.mat` inputs (not verified). |

## What the pipeline does, step by step
1. Loads `BAAA*.mat` for the cell (`IrgbM` → mask, crop window `xstart/xend/ystart/yend`, `FBR`, `SDs`, `SDt`, `fbrTen`).
2. Reads the TIRF snapshots (`Before_After/…/*.tif`; header comment: lower-numbered file = first movie, higher = later movie), crops, and detects clusters in each.
3. Keeps clusters that persist: overlap ≥ max(9 px, area/10) between the last frame of the first movie and the first frame of the second, and > 65 % overlap with the first movie's first frame.
4. Reads the whole IRM time series of the cell (`nFrames = 2048`).
5. For every frame and cluster centre (plus an equal-or-larger set of random background points): takes the 5×5 patch (`double(I)/35.625`), calls `curvature5x5_cubicFit(patch, 65)` (65 = nm per pixel).
6. Stores per cluster: curvature / Gaussian curvature / shape index / curvedness / class time series, mean and SD of mean curvature, number and fraction of class changes, FBR SD / SDt / tension.
7. Saves the run (`Curvature_Analysis_Output_<runTimestamp>`, never overwrites older runs), plus a `_latest` copy.

Classes (shape-index bins, Koenderink): ≤ −2/3 CUP/PIT; (−2/3, −1/3] TROUGH; (−1/3, 1/3) SADDLE; [1/3, 2/3) RIDGE; ≥ 2/3 DOME/HILL.
In the thesis, CUP/PIT + TROUGH are called outward-bending and RIDGE + DOME/HILL inward-bending.

## Settings to check before re-running
* **Paths** (`rootFolder`, `folder2`, plate/set loops) are hard-coded to `/Volumes/T7 Touch/Forcurvature/…`.
* **Random background size**: `nRandomTarget = 5 * nClust` here. The thesis control run used 1 point per cluster (n=200, see top-level README caveat 2). Use `nRandomTarget = nClust` to match.
* **Flat tolerance** (`curvature5x5_cubicFit.m`, lines 66–68): `tol = max(1e-8, 0.01*curvedness)`; `if curvedness < tol` → FLAT. Because `0.01*curvedness < curvedness` for any curvedness > 0, only patches with curvedness < 1e-8 are ever called FLAT, so in practice every patch receives one of the five classes. Not changed, because the figures were produced with this behaviour.
* `curvature5x5_fit.m` (older quadratic-fit version) is **not** used and not included.
