# runAllSets_TensionAndCorrelationAnalysis.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-4%20statistics-lightgrey) ![MATLAB](https://img.shields.io/badge/MATLAB-R2019b%2B-orange)

Batch runner that applies the tension-KDE and pooled-correlation analyses to every `Set*` folder.

## Syntax

```matlab
batchResult = runAllSets_TensionAndCorrelationAnalysis                         % uses this file's folder
batchResult = runAllSets_TensionAndCorrelationAnalysis(parentDir)
batchResult = runAllSets_TensionAndCorrelationAnalysis(parentDir, outputRoot, Name, Value)
```

## Expected folder layout

```
parentDir/
├── Set1/   TNFR1_full_workspace_001.mat, ...   (or full/ sub-folder, or full.zip)
├── Set2/
└── SetN/
```

## Options

| Name | Default | Description |
|---|---|---|
| `setNames` | auto-discover `Set*` | Cell array of sets to run |
| `inputFolderName` / `inputZipName` | `'full'` / `'full.zip'` | Fallback locations of the MAT files |
| `runKDE`, `runCorrelations` | `true` | Turn each analysis on/off |
| `continueOnError` | `true` | Keep going if one set fails |
| `minWholeN`, `minPunctaN` | `20`, `3` | Minimum values per cell for KDE |
| `gridN`, `gridPercentiles` | `200`, `[1 99]` | KDE grid |
| `makePerCellPlot` | `true` | Extra per-cell KDE figures |
| `mannWhitneyMetric` | `'median'` | `'mean'` or `'median'` |
| `correlationMinN` | `3` | Minimum pairs for a correlation |

## Files needed

| File | Role |
|---|---|
| `runSet1_TensionKDE.m` | Called for each set |
| `runSet1_PooledPunctaCorrelations.m` | Called for each set |
| `TNFR1_full_workspace_*.mat` | Output of [`follow_ccp_jibitesh_ver8_stuckpuncta.m`](README_follow_ccp_jibitesh_ver8_stuckpuncta.md) |

## Outputs

In `<outputRoot>` (default `parentDir/all_sets_analysis_output`):

- `<SetName>/tension_kde_output/` and `<SetName>/pooled_puncta_correlation_output/`
- `all_sets_batch_result.mat` and `all_sets_run_summary.csv` (status and error message per set)

The returned `batchResult` holds `RunSummary`, `KDEResults` and `CorrelationResults`.

## Important

`createMasterPunctaTableFromBatch.m` expects `batch.mat`, which this function does **not** write. Save it manually:

```matlab
save(fullfile(parentDir, 'batch.mat'), 'batchResult');
```
