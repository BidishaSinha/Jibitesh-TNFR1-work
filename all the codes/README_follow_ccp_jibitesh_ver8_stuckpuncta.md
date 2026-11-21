# follow_ccp_jibitesh_ver8_stuckpuncta.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![stage](https://img.shields.io/badge/stage-3%20puncta%20mapping-lightgrey)

Detects TIRF puncta ("clusters") in a **before** and an **after** image, identifies the puncta that remain stuck at the same position, extracts line-scan **kymographs**, and assigns each stuck punctum the membrane **tension, SDt and SDs** of the FBR it sits in.

## What it does

1. Loads the IRM result for one cell (`IrgbM`, `xstart`, `xend`, `ystart`, `yend`, `FBR`, `fbrTen`, `SDs`, `SDt`) and builds a mask from the IRM image.
2. Reads the TIRF frames (`003.tif` = before, `004.tif` = after) and crops them to the IRM region.
3. Detects puncta with `adaptthresh(0.3)` + morphological clean-up; keeps objects with `ThreshA = 10 < area < ThreshB = 5000` and mean intensity `> thresh = 200`.
4. Builds 13-pixel line-scan kymographs centred on each punctum's centroid.
5. A punctum counts as **stuck** if it is present in at least 85 % of frames and also in the "before" image.
6. For stuck puncta inside an FBR, stores:
   - `ten`, `intstuck`, `areastuck` (tension-mapped)
   - `sdt`, `sds`, `intstuckb`, `areastuckb` (SD-mapped)
7. Plots a 3 × 3 panel of correlations (intensity, total intensity and area vs tension, SDt and SDs).
8. Saves the workspace as `TNFR1_full_workspace_001.mat`.

## Files needed

| File | Role |
|---|---|
| `<…>\BAAAna<name>Cell_<nn>.mat` | IRM result from [`Multifol_findFBRnew.m`](README_Multifol_findFBRnew.md) |
| `003.tif`, `004.tif` (+ TIRF stack in the folder) | Before / after TIRF images |
| Image Processing Toolbox | thresholding, `regionprops` |

## Usage

1. Edit the hard-coded paths and file names at the top (`cd(...)`, `load(...)`, `imread(...)`).
2. Set `con` (condition label) and `sncell` (cell number); keep `GETALLCEN = 'n'` on the first run as written in the script comment.
3. Run the script. Rename the saved workspace to `TNFR1_full_workspace_<###>.mat` for each cell so the batch scripts can find it (pattern `TNFR1_full_workspace_*.mat`).

## Outputs

- `TNFR1_ALLSTATS_<n>_tillframe_<n>.mat` – detected object statistics
- `TNFR1_full_workspace_001.mat` – variables consumed downstream (`ten`, `areastuck`, `intstuck`, `sdt`, `sds`, `areastuckb`, `intstuckb`, `fbrTen`, …)
- Figures 3–6: labelled objects, kymographs, correlation panels

## Known issues

- The line `elseoffset=0;` is a typo for `else offset=0;`; as written `offset` stays undefined when `kk == 2`.
- In the `kk == 2` branch the `imread(...)` result is not assigned to a variable.
- Fix both before batch use.

## Next step

Feed the saved workspaces to [`runAllSets_TensionAndCorrelationAnalysis.m`](README_runAllSets_TensionAndCorrelationAnalysis.md).
