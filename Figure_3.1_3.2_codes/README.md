# Code package for thesis Figures 3.1 and 3.2

Everything needed to trace Figures 3.1 (basal membrane curvature at TNFR1 clusters) and 3.2 (effect of TNFα) from raw
IRM/TIRF data to the finished figure pages.

```
Figure_3.1_3.2_codes/
├── README.md                      <- this file (overview, panel map, settings, caveats)
├── 01_data_generation/            <- MATLAB pipeline: object detection + per-frame curvature + FBR SDt/tension
│   ├── README.md
│   └── upstream/                  <- script that (most likely) produced the BAAA*.mat inputs
├── 02_statistics_and_plots/       <- MATLAB: statistics + the individual saved plots (.png/.pdf/.fig)
│   └── README.md
├── 03_figure_assembly/            <- MATLAB + Python: re-export panels at 7 pt, assemble the thesis pages
│   ├── README.md
│   ├── panels_fig3_1/, panels_fig3_2/   <- the final per-panel PDFs
└── final_figures/                 <- Figure_3.1 / Figure_3.2 (vector PDF)
```

## Pipeline in one paragraph
For every cell, TNFR1 clusters are detected on single-frame **TIRF fluorescence** snapshots (`Before_After/…/*.tif`).
Curvature is then computed on the **IRM** time series (2048 frames per cell, folder `<root>/00N/set/*.tif`):
for each cluster centre and each frame a 5×5-pixel patch (pixel = 65 nm; intensity ÷ 35.625) is fitted with a cubic surface,
giving mean/Gaussian curvature, principal curvatures, shape index and curvedness; the shape index is binned
(Koenderink) into CUP/PIT, TROUGH, SADDLE, RIDGE, DOME/HILL. Per cluster the pipeline stores the time series, SD of mean
curvature, number of class changes, and the local membrane-fluctuation readouts (FBR SDtime, SDspace, tension; FBR = 12×12 px)
looked up from the BAAA*.mat file of that cell. The same is done for randomly placed background points. The analysis scripts
then compute per-cell class percentages, Mann–Whitney / Kruskal–Wallis / Spearman statistics, and write the plots.

## Which script/run produced which panel
Data-folder root: `/Volumes/T7 Touch/Forcurvature/`

### Figure 3.1 — control, 200 clusters, 20 cells, 3 sets
Script: `02_statistics_and_plots/plot_all_curvature_analyses.m` (run on `with_good_cells/set7/Plate8/Exported/Curvature_Analysis_Output_20260807_094538`).
The panels used are in `…/Curvature_Analysis_Output_20260807_094538/MATLAB_SessionAnalysis_20260812_130033/`.

| Panel | Content | Saved plot | Test shown |
|---|---|---|---|
| a | % of clusters per class, mean ± SEM over cells (and sets); pooled % under labels | `B1_classpct_snapshot` | – |
| b | mean curvature by class | `B2_curvature_by_class_snapshot` | Kruskal–Wallis |
| c | SD of mean curvature, cluster vs random background | `C1_SDcurvature_cluster_vs_random` | Mann–Whitney, n=200 vs 200 |
| d | class mix, cluster vs random | `C3_classmix_cluster_vs_random` | per-class, ridge significant |
| e | SDtime vs number of curvature sign flips | `A7_SDt_vs_NFlips` | Spearman |
| f | Spearman correlation heat map | `A9_correlation_heatmap_small` | Spearman |

### Figure 3.2 — Control vs TNFα (a–f) and New vs Pre-existing clusters (g–k)
| Panel | Content | Saved plot | Script | Run folder |
|---|---|---|---|---|
| a | class % Control vs TNFα | `N1_classmix_control_vs_tnfa` | `plot_control_vs_tnfa_comparison.m` | `with_good_cells/set7/Plate8/MATLAB_Control_vs_TNFa_20260813_002339` |
| b | FBR SDtime | `N3_SDt_control_vs_tnfa` | same | same |
| c | FBR tension | `N4_Tension_control_vs_tnfa` | same | same |
| d | SD of mean curvature | `N5_SDcurvature_control_vs_tnfa` | same | same |
| e | SDt vs SD of curvature (both groups) | `N8_SDt_vs_SDcurvature_control_vs_tnfa` | same | same |
| f | SDt vs fraction of class changes | `N9_SDt_vs_FracClassChanges_control_vs_tnfa` | same | same |
| g | area, New vs Pre-existing | `Q1_Area_new_vs_preexisting` | `plot_new_vs_preexisting_clusters.m` | `For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260812_203348/MATLAB_New_vs_PreExisting_20260813_200546` |
| h | circularity | `Q2_Circularity_new_vs_preexisting` | same | same |
| i | mean intensity | `Q5_MeanIntensity_new_vs_preexisting` | same | same |
| j | class mix, New vs Pre-existing | `Q11_classmix_new_vs_preexisting` | same | same |
| k | SD of mean curvature, New vs Pre-existing | `Q9_SDcurvature_new_vs_preexisting` | same | same |

Underlying runs: Control = `with_good_cells/set7/Plate8/Exported/Curvature_Analysis_Output_20260807_094538`;
TNFα (all 84 clusters) = `For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260812_203348`;
TNFα pre-existing-only (25 clusters, used only to label clusters as pre-existing) = `…/Curvature_Analysis_Output_20260813_174118`.

## How to reproduce (order)
1. `01_data_generation` — run the control pipeline (`…samecell.m`) and the TNFα pipeline (`…samecell_tnfa.m`). Each creates a timestamped `Curvature_Analysis_Output_<time>` folder (needs the drive layout described in that README).
2. `02_statistics_and_plots` — edit the SETUP paths if your run folders differ, then run `plot_all_curvature_analyses.m` (3.1), `plot_control_vs_tnfa_comparison.m` and `plot_new_vs_preexisting_clusters.m` (3.2). Each writes a `MATLAB_*` folder of plots.
3. `03_figure_assembly` — run `figure3_1_panels_from_saved_figs.m` / `figure3_2_panels_from_saved_figs.m` (MATLAB; re-exports the saved `.fig` panels at readable size), then `python3 figure3_1_compose.py` / `figure3_2_compose.py` (PyMuPDF) to assemble the pages into `final_figures/`.

Software: MATLAB R2024b with Statistics and Image Processing toolboxes; Python 3 with PyMuPDF (`import fitz`).
All data paths are absolute (`/Volumes/T7 Touch/...`) and the T7 Touch drive must be mounted.

## Things to know before relying on this package
1. **Original analysis scripts pointed elsewhere.** The copies here have only their SETUP path lines changed (marked at the top of each file) so that they point at the runs listed above. In their original state `plot_all_curvature_analyses.m` and `plot_control_vs_tnfa_comparison.m` pointed at the *pre-existing-only* run (25 clusters); using that for Figure 3.2 a–f gives n2=25 instead of the thesis's 84.
2. **Random-background size.** The thesis figures 3.1 c/d and 3.2 use a random set of **200 points (1 per cluster)** from the 7 Aug control run. The pipeline files saved here (edited 11 Aug onward) use `nRandomTarget = 5 * nClust` (1000 points); later control runs (e.g. `…20260812_132821`) have n2=1000 and give p=0.044 for 3.1c and a non-significant ridge in 3.1d. To regenerate the thesis numbers with the code in this folder, change that line to `nRandomTarget = nClust` (random points are re-drawn each time, so p values will differ slightly). **The exact code version that produced the 7 Aug run was not saved**, and nothing else in the pipeline was checked for changes between 7 and 11 Aug.
3. **Control source for Figure 3.2 a–f.** The control values match Figure 3.1 (same 200 clusters). The `…20260813_002339` comparison run was made with an earlier version of the comparison script; its control folder is not recorded, so `20260807_094538` is used here (same n).
4. **Flat-patch tolerance.** In `curvature5x5_cubicFit.m` the tolerance is `tol = max(1e-8, 0.01*curvedness)` and a patch is called FLAT if `curvedness < tol`. The 1 % term can never trigger (it compares curvedness with a fraction of itself), so the effective rule is `curvedness < 1e-8`, which essentially never occurs; every patch is classified by its shape index. See `01_data_generation/README.md`.
5. **FBR / SDtime / tension inputs** come from `BAAA*.mat` files created before this pipeline runs. `upstream/Multifol_findFBRnew.m` (the FBR script stored next to the data) is included as the probable generator; this was not verified.
6. **New vs Pre-existing** (Fig 3.2 g–k) is defined by spatial matching (cluster centroid, `XC/YC`, within 15 px, same cell) between the all-clusters run and the pre-existing-only run: matched = pre-existing (24 of the 25), unmatched = new (60), n = 84.
