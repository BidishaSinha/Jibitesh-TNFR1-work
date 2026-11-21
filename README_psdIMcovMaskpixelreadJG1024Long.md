# psdIMcovMaskpixelreadJG1024Long.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-1%20PSD-lightgrey)

Computes a **per-pixel PSD** of intensity/height time series using the autoregressive covariance method (`pcov`) for every pixel inside a binary mask.

## Syntax

```matlab
psdIMcovMaskpixelreadJG1024Long(dname, directoryname, BW, sps, conv, order, wannasave, rem)
```

All **eight** arguments are required; otherwise the function prints its usage and returns.

| Argument | Description |
|---|---|
| `dname` | Folder containing the `.tif` frames (path ending in `...\<id>\set`) |
| `directoryname` | Folder in which the `pcov` output sub-folder lives |
| `BW` | Binary mask, same size as one frame; PSD is computed only where `BW == 1` |
| `sps` | Sampling rate in Hz |
| `conv` | Divisor applied to raw intensities (calibration factor) |
| `order` | Model order passed to `pcov` |
| `wannasave` | `'y'` to save results, `'n'` otherwise |
| `rem` | Label inserted in the output file name, e.g. `'cell'` or `'Backg'` (character vector) |

## How it works

- Frames are processed in blocks of **2048**; the number of files must be a multiple of 2048 (each block is one repeat).
- Each pixel's time series is mean-detrended and passed to `pcov(x, order, 2048, sps)`, giving **1025** frequency bins.
- Frames larger than ~1 M pixels are tiled in 512-pixel blocks and saved tile-by-tile as `allpsd2_<N1>_<N2>_<M1>_<M2><rem>.mat`.

## Files needed

- `.tif` stack in `dname`
- Signal Processing Toolbox (`pcov`)
- An existing `<directoryname>\pcov\` folder (created by `CalculatingPSDwithMaskinparts.m`)

## Outputs (when `wannasave = 'y'`)

- `<directoryname>\pcov\allpsd3_<rem>_<id>_<rep>.mat` – variable `allpsd3` (rows × cols × 1025)
- `<directoryname>\pcov\allpsd2X.dat` – frequency vector

## Example

```matlab
load('pcov\BW.mat');                       % BW, BWbck
psdIMcovMaskpixelreadJG1024Long(d_name, d_name, BW, 20, 42.58174, 32, 'y', 'cell');
```

## Notes

- Uses Windows path separators (`\`).
- The three-character id in the file name is taken from characters `end-6:end-4` of `dname`.
- Typically called by [`CalculatingPSDwithMaskinparts.m`](README_CalculatingPSDwithMaskinparts.md).
