# GettingbatchResult.docx – statistics workflow notes

![type](https://img.shields.io/badge/type-workflow%20notes-lightgrey)

This Word document is not code. It records the **command sequence** that connects the batch statistics scripts. The steps are reproduced below in cleaned form.

## Sequence

```matlab
% 1. Run all sets (KDE + pooled correlations)
batchResult = runAllSets_TensionAndCorrelationAnalysis;

% 2. Save the result manually as batch.mat
save('batch.mat', 'batchResult');

% 3. Build the master table (MAT, plus optional CSV)
batchMatFile  = '<path>/batch.mat';
outputMatFile = '<path>/MasterPunctaTable.mat';
MasterPunctaTable = createMasterPunctaTableFromBatch(batchMatFile, outputMatFile);

createMasterPunctaTableFromBatch(batchMatFile, outputMatFile, '<path>/MasterPunctaTable.csv');

% 4. Load / inspect the master table (optional)
load('<path>/MasterPunctaTable.mat')

% 5. Run linear mixed-effects models
runAllSets_LMMAnalysis_v5('MasterPunctaTable.mat', 'LMM_Output');
```

## Scripts involved

| Step | Script | README |
|---|---|---|
| 1 | `runAllSets_TensionAndCorrelationAnalysis.m` | [link](README_runAllSets_TensionAndCorrelationAnalysis.md) |
| 3 | `createMasterPunctaTableFromBatch.m` | [link](README_createMasterPunctaTableFromBatch.md) |
| 5 | `runAllSets_LMMAnalysis_v5.m` | [link](README_runAllSets_LMMAnalysis_v5.md) |

## Notes

- The original notes contain machine-specific absolute paths; replace them with your own.
- Step 2 is manual because the batch function does not save `batch.mat` itself.
- For a GitHub repository you may want to turn this sequence into a `run_pipeline.m` script and keep the `.docx` out of version control.
