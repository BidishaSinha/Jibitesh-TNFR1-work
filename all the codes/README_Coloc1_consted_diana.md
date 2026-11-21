# Coloc1_consted_diana.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![interactive](https://img.shields.io/badge/mode-interactive-orange)

Two-channel **STED colocalisation** analysis in user-drawn ROIs. Channel 1 is handled as `TFSTED` and channel 2 as `TNFR1STED` (as labelled in the script); the variable names `AP2s` / `Cls` in the outputs refer to channel 1 and channel 2 respectively.

## What it does

For each cell (`cll = 1:17`) and each of 6 ROIs per cell:

1. Loads `<cell>_1.tiff` and `<cell>_2.tiff` from the input folder `f1`.
2. You draw a rectangular ROI (`drawrectangle`) on channel 2.
3. Both channels are cropped, binarised with `adaptthresh(…, 0.6)`, cleaned (erode/dilate/fill holes) and size-filtered (`ThreshA = 5 < area < ThreshB = 700` pixels).
4. Overlapping pixels of the two binary masks give the colocalisation.
5. Per-ROI metrics are accumulated.

## Files needed

| File | Role |
|---|---|
| `001_1.tiff`, `001_2.tiff`, … | Channel 1 and 2 images per cell, 3-digit numbering, in folder `f1` |
| Image Processing Toolbox | thresholding, morphology, `regionprops` |

## Usage

1. Set `f1` to your image folder (single backslashes in a normal MATLAB string, e.g. `'I:\...\Control'`).
2. Change `1:17` to the number of cells and `1:6` to the number of ROIs per cell if needed.
3. Adjust `ThreshA`, `ThreshB` if your puncta size differs.
4. Run and draw each ROI.

## Outputs

- `<n>statsstedn.mat` – `statsAP2s`, `statsCs` (region properties) for each ROI
- `<n>coloc28_new3.mat` with, per ROI:

| Variable | Meaning |
|---|---|
| `colocAs` | Overlapping pixel count |
| `colocAFs` | Overlap as a fraction of ROI area |
| `totAAp2s`, `totCls` | Total detected pixels in channel 1 / channel 2 |
| `AFAPs`, `AFCLs` | Area fraction of channel 1 / channel 2 |
| `colocAAp2s` | % of channel 1 pixels overlapping channel 2 |
| `colocCLs` | % of channel 2 pixels overlapping channel 1 |

## Notes

The folder path is hard-coded; update it before running.
