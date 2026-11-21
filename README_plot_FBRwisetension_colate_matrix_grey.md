# plot_FBRwisetension_colate_matrix_grey.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![interactive](https://img.shields.io/badge/mode-interactive-orange)

Renders **tension maps** as colour images: each accepted FBR is painted with its tension value on a grey background.

## What it does

1. Opens a multi-select dialog for `B*AAAna*.mat` files from [`Multifol_findFBRnew.m`](README_Multifol_findFBRnew.md).
2. For each file creates an image the size of `FBinM3` and fills each accepted 12 × 12 px FBR (`fbrsize = 12`, from `fbrRS` / `FBR` / `fbrTen`) with its tension.
3. Colour scale: `jet`, tension display range **0–100**; pixels without an FBR are grey (`[0.5 0.5 0.5]`).
4. Displays the map and saves it as a TIFF.

## Files needed

`B*AAAna*.mat` containing `fbrRS`, `FBR`, `fbrTen`, `FBinM3`.

## Usage

Run the script and select the files. Adjust `map_lower_lim`, `map_upper_lim` and the `[0 100]` range in `mat2gray` to change the colour scale.

## Output

`<mat-file-name>.mat.tif` for each file (the `.tif` is appended to the full MAT file name).

## Note

Keep `fbrsize` equal to `M`/`N` used when the FBRs were created.
