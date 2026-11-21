# psdsimfunc6.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![stage](https://img.shields.io/badge/stage-2%20fitting-lightgrey)

Theoretical **PSD model** of membrane fluctuations. It is the model function that `fitPSD.m` fits to measured spectra.

## Syntax

```matlab
y = psdsimfunc6(AT, cytvis, f, sig, x)
```

| Argument | Description |
|---|---|
| `AT` | Amplitude-type fit parameter |
| `cytvis` | Cytoplasmic-viscosity-type fit parameter |
| `f` | Activity/force-type fit parameter |
| `sig` | Tension-type fit parameter |
| `x` | Frequency vector (Hz) |
| `y` | Model PSD evaluated at `x` |

## Implementation details

- Fixed constants inside the file: `kap = 0.6`, `mu = 0`.
- The spectrum is a **sum over mode index 10 to 1250** for every frequency in `x`.
- A commented-out `integral` version is kept in the file for reference; the comment cites *Biophys. J.* 108(12) 2794 for the extra `mu` term.

## Files needed

None – it is self-contained. It must be on the MATLAB path because `fitPSD.m` refers to it by name inside `fittype`.

## Example

```matlab
x = linspace(0.1, 10, 90)';
y = psdsimfunc6(2, 2e4, 0.1, 1, x);
loglog(x, y)
```

## Notes

- Change `kap` / `mu` here if your model assumptions differ.
- Called through [`fitPSD.m`](README_fitPSD.md).
