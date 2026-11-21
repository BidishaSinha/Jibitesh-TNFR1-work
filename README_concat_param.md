# concat_param.m

![type](https://img.shields.io/badge/type-MATLAB%20script-blue) ![interactive](https://img.shields.io/badge/mode-interactive-orange)

Collects fitted parameters from many cells into single vectors, together with **per-cell medians**, for downstream plotting and statistics.

## What it does

1. Opens a multi-select dialog; choose the `B*AAAna*.mat` result files from [`Multifol_findFBRnew.m`](README_Multifol_findFBRnew.md).
2. For each file, appends (column 2 of each array) to pooled vectors and appends the **median** to per-cell vectors.

| Pooled (all FBRs) | Per-cell median | Source variable |
|---|---|---|
| `Tenall` | `Ten_c` | `fbrTen` |
| `SDs_all` | `SDsc` | `SDs` |
| `SDt_all` | `SDtc` | `SDt` |
| `Conall` | `Con_c` | `fbrC` |
| `Visall` | `Vis_c` | `fbrV` |
| `Acall` | `Ac_c` | `fbrAc` |

3. Saves everything to `ct2a.mat`.

## Files needed

`B*AAAna*.mat` files containing `fbrTen`, `SDs`, `SDt`, `fbrC`, `fbrV`, `fbrAc`.

## Usage

Run the script, select the files for **one condition**, and rename `ct2a.mat` afterwards (e.g. `control.mat`, `tnfa.mat`) before running the next condition, otherwise it will be overwritten.

## Output

`ct2a.mat` in the current folder.
