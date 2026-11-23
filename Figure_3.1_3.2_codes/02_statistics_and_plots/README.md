# 02 — Statistics and saved plots (MATLAB)

Each script reads one or two `Curvature_Analysis_Output_<timestamp>/AllCells_CurvatureTopology_TimeSeries.mat` files,
computes the statistics and writes each plot as `.png`, `.pdf` and `.fig` into a new `MATLAB_*` sub-folder next to the data.
Run a script with F5 (or `matlab -batch "run('<file>.m')"`). Set the folders in the SETUP block at the top first.

| Script | Used for | SETUP in this copy |
|---|---|---|
| `plot_all_curvature_analyses.m` | **Figure 3.1** (also many extra analyses A–L: SDt/tension correlations, class %, cluster-vs-random, sign flips, transitions…) | `rawFolder` = control run `…set7/Plate8/Exported/Curvature_Analysis_Output_20260807_094538`; `avgFolder = ''` |
| `plot_control_vs_tnfa_comparison.m` | **Figure 3.2 a–f** (Control vs all 84 TNFα clusters; plots `N1…N21`) | `controlFolder` = `…20260807_094538`; `tnfaFolder` = `…For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260812_203348` |
| `plot_new_vs_preexisting_clusters.m` | **Figure 3.2 g–k** (New vs Pre-existing clusters; plots `Q1…Q11`, `R1…R10`) | unchanged: all-clusters run `…20260812_203348`, pre-existing-only run `…20260813_174118` |

Only the SETUP path lines of the first two scripts differ from the originals (marked at the top of those files).

## Definitions used in the plots
* **Class of a cluster ("single-snapshot")**: shape-index class of the first IRM frame. Class mix per cell is computed first; bars show the mean ± SEM over cells (`classPercentBySEM`); Figure 3.1a also shows SEM over sets, and the pooled percentage under each label.
* **Number of sign flips**: number of sign changes of the mean-curvature time series over 2048 frames (computed in `flattenClusterStats`).
* **SD of mean curvature**: SD over all frames of the cluster's mean curvature. **Fraction of class changes**: fraction of consecutive frames in which the class changed.
* **Tests**: Mann–Whitney U (two groups), Kruskal–Wallis (class comparison), Spearman correlation (scatter / heat map), class-by-class cluster-vs-random comparison with significance markers (ns, *, **).
* **New vs Pre-existing**: each cluster of the all-clusters run is matched to the pre-existing-only run by centroid (`XC/YC`) within 15 px, same cell/set/plate. Matched = pre-existing, unmatched = new.
* Box plots limit the y-axis to the whisker range so far outliers do not compress the plot (a few outliers are therefore not visible).

## Outputs used for the thesis
See the panel table in the top-level `README.md` (file names `B1/B2/C1/C3/A7/A9` for Figure 3.1, `N1/N3/N4/N5/N8/N9` and `Q1/Q2/Q5/Q9/Q11` for Figure 3.2).
