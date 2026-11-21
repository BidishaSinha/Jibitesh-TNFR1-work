# fitPSD.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-2%20fitting-lightgrey)

Fits the mean PSD of each analysis region (FBR) with the model in `psdsimfunc6.m` and returns the fitted parameters and goodness of fit.

## Syntax

```matlab
[FfbrAc, FfbrC, FfbrRS, FfbrTen, FfbrV] = fitPSD(yallsB, xx, rf)
```

| Input | Description |
|---|---|
| `yallsB` | Matrix of background-subtracted PSDs, one **column per FBR** |
| `xx` | Frequency vector (column) matching the rows of `yallsB` |
| `rf` | Number of FBRs (columns) to fit |

| Output (1 × rf) | Source | Meaning |
|---|---|---|
| `FfbrAc` | `AT` | Amplitude-type parameter |
| `FfbrV` | `0.01 × cytvis` | Viscosity-type parameter |
| `FfbrC` | `ff` | Activity/force-type parameter |
| `FfbrTen` | `50 × sig` | **Tension** |
| `FfbrRS` | R² | Goodness of fit |

## Fit settings

- Weights: `1 ./ xx`
- Parameter order `[AT, cytvis, ff, sig]`
- Lower bounds `[1, 1, 0, 0]`, upper bounds `[10, 1e8, 1, 1000]`, start point `[1, 20000, 0, 1]`

## Files needed

| File | Role |
|---|---|
| `psdsimfunc6.m` | Model function referenced by `fittype` |
| Curve Fitting Toolbox | `fit`, `fittype`, `fitoptions`, `prepareCurveData` |

## Example

```matlab
[Ac, C, RS, Ten, V] = fitPSD(yallsB, xx, size(yallsB, 2));
good = RS > 0.999 & Ten > 0.05 & Ac < 9.5;   % filter used in Multifol_findFBRnew.m
```

## Notes

- Called from [`Multifol_findFBRnew.m`](README_Multifol_findFBRnew.md), which applies the quality filter shown above.
- Edit the bounds in this file if fits hit the limits.
