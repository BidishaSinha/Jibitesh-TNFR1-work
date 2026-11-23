# 03 — Assembling the thesis figure pages

The plots from step 02 are saved at a large size with their own titles. These scripts re-export the saved `.fig` files at a
readable size (7 pt text), apply the cosmetic edits below, and place the panels on one vector PDF page per figure.

| File | What it does |
|---|---|
| `figure3_1_panels_from_saved_figs.m` | Opens the six Figure 3.1 `.fig` files (from `…20260807_094538/MATLAB_SessionAnalysis_20260812_130033/`) and writes one PDF per panel into `panels_fig3_1/`. |
| `figure3_1_compose.py` | Assembles panels a–f (3 × 2) into `../final_figures/Figure_3.1_rebuilt_from_saved_plots.pdf`; draws the **Outward bending** / **Inward bending** brackets under panels a, b, d (positions read from each panel PDF's tick-label text); panel letters sit in their own margin. |
| `figure3_2_panels_from_saved_figs.m` | Same for the eleven Figure 3.2 `.fig` files (Control-vs-TNFα run `…20260813_002339` for a–f, New-vs-Pre-existing run `…20260813_200546` for g–k) → `panels_fig3_2/`. |
| `figure3_2_compose.py` | Assembles panels a–k (rows a–d, e–h, i–k) into `../final_figures/Figure_3.2_rebuilt_from_saved_plots.pdf`; brackets under the class-axis panels a and j. |
| `panels_fig3_1/`, `panels_fig3_2/` | The final per-panel PDFs (so the compose scripts run without MATLAB). |

Run: `python3 figure3_1_compose.py` and `python3 figure3_2_compose.py` (needs PyMuPDF). Re-run the MATLAB scripts only if you change a panel; the `.fig` source files must be reachable on the T7 Touch drive.

## Edits applied to the saved plots (no data are changed)
* Panel titles removed, except Figure 3.1 a ("Class % (single-snapshot) -- cells n=20, sets n=3") and b ("Mean curvature by class"), as in the thesis.
* All text set to 7 pt; the Mann–Whitney line moved under the axis (box plots) or into extra x-label lines (3.2 e, f) so it cannot cover data; the Figure 3.1 b Kruskal–Wallis line stays inside the axes.
* Class tick labels on two lines (CUP/ PIT, DOME/ HILL); in 3.1a the pooled percentages stacked under them; Figure 3.1a percentages moved above the error bars and the y-axis extended to 60; Figure 3.1d y-axis to 68 with the legend top-left; Figure 3.2j legend top-left with y-axis to 72.
* Figure 3.1f: footnote explaining the stars removed; numbers shown as value over stars.
* Figure 3.2: condition written "TNFα"; Control p printed as "p<1e-16" instead of "p=0" in 3.2e; **p values in bold** (3.2 b–i, k). Figure 3.1 p values are not bold.
* Original y-ranges are kept in the box plots, so far outliers stay clipped as in the saved plots.
