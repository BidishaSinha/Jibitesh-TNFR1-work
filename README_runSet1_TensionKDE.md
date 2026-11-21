# runSet1_TensionKDE.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-4%20statistics-lightgrey) ![MATLAB](https://img.shields.io/badge/MATLAB-R2019b%2B-orange)

Compares **whole-cell** membrane tension with **puncta-localised** tension using kernel density estimates (KDE), averaged across cells (mean ± SEM), with Mann–Whitney tests.

Despite the name, it works for any set when `setLabel` is passed.

## Syntax

```matlab
result = runSet1_TensionKDE(set1Dir, outputDir)
result = runSet1_TensionKDE(set1Dir, outputDir, Name, Value)
```

`set1Dir` may be a folder (with the MAT files directly or one level down) or a `.zip` file.

## Key options

| Name | Default | Description |
|---|---|---|
| `filePattern` | `'TNFR1_full_workspace_*.mat'` | Input MAT files |
| `fbrTenVariable` / `punctaTenVariable` | `'fbrTen'` / `'ten'` | Variable names |
| `fbrTenColumn` | `2` | Column of `fbrTen` holding tension |
| `gridN`, `gridPercentiles` | `200`, `[1 99]` | Common x-grid for KDEs |
| `minWholeN`, `minPunctaN` | `20`, `3` | Minimum values per cell |
| `bandwidth` | `NaN` (automatic) | KDE bandwidth |
| `mannWhitneyMetric` | `'median'` | Per-cell `'mean'` or `'median'` |
| `makePerCellPlot` | `true` | Extra figures |
| `setLabel` | `'Set1'` | Prefix for output names |

## Method

1. Whole-cell tension: `fbrTen(:,2)`; puncta tension: `ten`. Non-finite and non-positive values are dropped.
2. KDE per cell on a shared grid (positive support), then mean ± SEM across cells.
3. Per-cell summary (mean/median), paired differences, and "high-tension enrichment" (fraction above the whole-cell 75th percentile).
4. Mann–Whitney (`ranksum`): once on **cell-level summaries** (cells are the statistical unit) and once on **pooled values**.

## Files needed

- `TNFR1_full_workspace_*.mat` containing `fbrTen` and `ten`
- Statistics and Machine Learning Toolbox (`ksdensity`, `ranksum`)

## Outputs (in `outputDir`)

`<Set>_tension_kde_result.mat`, `<Set>_cell_summary.csv`, `<Set>_cell_stats.csv`, `<Set>_mannwhitney_stats.csv`, `<Set>_pooled_mannwhitney_stats.csv`, and PNG/FIG files for the mean ± SEM plot, per-cell KDEs and puncta per-cell KDEs.

## Example

```matlab
result = runSet1_TensionKDE('Set1', fullfile('Set1','tension_kde_output'), 'setLabel', 'Set1');
```

Usually run through [`runAllSets_TensionAndCorrelationAnalysis.m`](README_runAllSets_TensionAndCorrelationAnalysis.md).
