# runAllSets_LMMAnalysis_v5.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-5%20modelling-lightgrey)

Fits **linear mixed-effects models** relating puncta features to membrane mechanics across all sets, with a random intercept per cell, and produces fitted-effect plots and ranked result tables.

## Model

```
Response ~ Predictor + (1 | SetID:CellID)
```

Nine models are fitted: each response in `{MeanIntensity, Area, TotalIntensity}` against each predictor in `{Tension, SDt, SDs}` (as coded in the `models` list inside the file – the first column is the response, the second the predictor).

## Syntax

```matlab
LMMResults = runAllSets_LMMAnalysis_v5(masterTableFile)
LMMResults = runAllSets_LMMAnalysis_v5(masterTableFile, outputDir)   % default 'LMM_Output'
```

`masterTableFile` can be a `.mat` (first variable is used – the `MasterPunctaTable`) or a spreadsheet/CSV readable by `readtable`.

## Required table columns

`SetID`, `CellID`, `MeanIntensity`, `Area`, `TotalIntensity`, `Tension`, `SDt`, `SDs`

Rows with `NaN` in the response or predictor are dropped for each model.

## Files needed

- `MasterPunctaTable.mat` from [`createMasterPunctaTableFromBatch.m`](README_createMasterPunctaTableFromBatch.md)
- Statistics and Machine Learning Toolbox (`fitlme`)

## Outputs (in `outputDir`)

| File | Content |
|---|---|
| `LMM_Results_Full.csv` | Beta, SE, t, DF, p, 95 % CI, N puncta/cells/sets, AIC, BIC, log-likelihood |
| `LMM_Results_Ranked.csv` | Same, sorted by p-value |
| `LMM_Results.mat` | `results`, `rankedResults` |
| `LME_<response>_vs_<predictor>.mat` | Each fitted model object |
| `LME_FittedEffects_3x3` (`.png`/`.fig`) | Scatter by set with population-level fit and CI |
| `LME_EffectSummary` (`.png`/`.fig`) | Forest plot of betas |
| `PredictionStruct.mat` | Predicted curves for re-plotting |

## Example

```matlab
res = runAllSets_LMMAnalysis_v5('MasterPunctaTable.mat', 'LMM_Output');
disp(sortrows(res, 'PValue'))
```

## Note

No multiple-comparison correction is applied across the nine models; apply one (e.g. Benjamini–Hochberg) if you report them together.
