# wholefieldSDmap.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue)

Computes and displays a **whole-field temporal standard-deviation map** of an IRM time series.

## What it does

1. Reads the first 2048 `.tif` frames from `dirname`.
2. Converts each frame with `(A − inmin) / conv` using `inmin = 3386.28017` and `conv = 32.64734`.
3. Takes the per-pixel standard deviation over time (`std(Im, 0, 3)`).
4. Shows the map with `imshow(imstd, [2 7])`, `jet` colormap and a colour bar.

## Files needed

A folder of at least 2048 `.tif` frames. No other scripts required.

## Usage

Set `dirname` (and the calibration constants for your acquisition), then run. Adjust the display range `[2 7]` as needed.

## Output

On-screen figure only; the variable `imstd` holds the map in the workspace. Save it with `imwrite` or `save` if needed.

## Notes

The whole stack is held in memory (`Im`); reduce the frame count for large images.
