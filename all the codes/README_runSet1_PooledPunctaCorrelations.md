# runSet1_PooledPunctaCorrelations.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-4%20statistics-lightgrey) ![MATLAB](https://img.shields.io/badge/MATLAB-R2019b%2B-orange)

Pools puncta from all cells of a set and computes pairwise **Spearman / Pearson correlations** between puncta features (area, intensity) and membrane mechanics (tension, SDt, SDs).

## Syntax

```matlab
result = runSet1_PooledPunctaCorrelations(set1Dir)
result = runSet1_PooledPunctaCorrelations(set1Dir, outputDir, Name, Value)
```

`set1Dir` can be a folder or a `.zip` file.

## Options

| Name | Default | Description |
|---|---|---|
| `filePattern` | `'TNFR1_full_workspace_*.mat'` | Input MAT files |
| `setLabel` | `'Set1'` | Used in output names |
| `minN` | `3` | Minimum valid pairs |
| `correlationTypes` | `{'Spearman','Pearson'}` | Correlation methods |

## Variables read from each MAT file

| Mapping | Variables |
|---|---|
| Tension-mapped | `areastuck`, `intstuck`, `ten` |
| SD-mapped | `areastuckb`, `intstuckb`, `sdt`, `sds` |

Tension and SD mappings can have different numbers of puncta. Rows are therefore kept separately with `NaN` for the missing quantity, and each pairwise correlation uses only rows where **both** variables are valid.

## Pooled table columns

`CellID, MappingType, PunctumLocalID, Area, MeanIntensity, TotalIntensity (= Area × MeanIntensity), Tension, SDt, SDs`

## Files needed

- `TNFR1_full_workspace_*.mat` from [`follow_ccp_jibitesh_ver8_stuckpuncta.m`](README_follow_ccp_jibitesh_ver8_stuckpuncta.md)
- Statistics and Machine Learning Toolbox (`corr`)

## Outputs (in `outputDir`)

- `<Set>_pooled_puncta_correlation_result.mat`
- `<Set>_pooled_puncta_table.csv`, `<Set>_pooled_puncta_cell_summary.csv`
- `<Set>_spearman_pairwise_correlations.csv`, `<Set>_pearson_pairwise_correlations.csv`
- `<Set>_spearman_correlation_heatmap` (`.fig` / `.png`)
- `<Set>_feature_vs_mechanics_scatter` (`.fig` / `.png`, 3 × 3 panels with n, rho, p)

## Notes

The returned `result.PooledPunctaTable` is what [`createMasterPunctaTableFromBatch.m`](README_createMasterPunctaTableFromBatch.md) merges across sets.
