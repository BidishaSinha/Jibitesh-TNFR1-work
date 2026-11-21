# createMasterPunctaTableFromBatch.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-4%20statistics-lightgrey) ![MATLAB](https://img.shields.io/badge/MATLAB-R2019b%2B-orange)

Merges the pooled puncta tables of every set stored in `batch.mat` into a single **MasterPunctaTable** (MAT and optional CSV) ready for modelling.

## Syntax

```matlab
MasterPunctaTable = createMasterPunctaTableFromBatch(batchMatFile)
MasterPunctaTable = createMasterPunctaTableFromBatch(batchMatFile, outputMatFile)
MasterPunctaTable = createMasterPunctaTableFromBatch(batchMatFile, outputMatFile, outputCsvFile)
```

| Argument | Default | Description |
|---|---|---|
| `batchMatFile` | – | MAT file containing `batchResult` |
| `outputMatFile` | `MasterPunctaTable.mat` next to the input | Output MAT |
| `outputCsvFile` | `''` (none) | Optional CSV copy |

## Input expectations

`batchResult.CorrelationResults.<SetName>.PooledPunctaTable` must exist for each set (produced by [`runAllSets_TensionAndCorrelationAnalysis.m`](README_runAllSets_TensionAndCorrelationAnalysis.md)). Sets with missing, non-table or empty tables are skipped with a warning.

## What it does

1. Loads `batchResult` and loops over all sets.
2. Adds a **`SetID`** column (the set name) as the first column.
3. Concatenates all rows and builds `setSummary` (rows, cells, counts of tension-/SD-mapped puncta, valid Tension/SDt/SDs).

## Outputs

- `outputMatFile` with variables `MasterPunctaTable` and `setSummary`
- Optional CSV of the table
- A message with the number of rows and sets

## Example

```matlab
T = createMasterPunctaTableFromBatch('batch.mat', 'MasterPunctaTable.mat', 'MasterPunctaTable.csv');
```

## Next step

[`runAllSets_LMMAnalysis_v5.m`](README_runAllSets_LMMAnalysis_v5.md)
