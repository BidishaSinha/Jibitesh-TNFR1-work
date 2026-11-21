# ReadImageJROI.m

![type](https://img.shields.io/badge/type-MATLAB%20function-blue) ![licence](https://img.shields.io/badge/licence-GPL--3.0-green) ![third-party](https://img.shields.io/badge/origin-third--party-lightgrey)

Reads ImageJ binary ROI files (`.roi`) and ROI archives (`.zip`) into MATLAB structures.

> **Third-party code.** Author: Dylan Muir (<dylan.muir@unibas.ch>), © 2011–2016, released under the **GNU GPL v3 or later**. Keep the original header when redistributing.

## Syntax

```matlab
sROI    = ReadImageJROI('cell.roi');            % single ROI -> struct
cvsROIs = ReadImageJROI({'a.roi','b.roi'});     % list -> cell array
cvsROIs = ReadImageJROI('RoiSet.zip');          % archive -> cell array
```

## Returned fields

Always present: `strName`, `strType`, `vnRectBounds`, `nVersion`, `vnPosition`.

Supported `strType` values: `Rectangle`, `Oval`, `Line`, `Polygon`, `Freehand`, `Traced`, `PolyLine`, `FreeLine`, `Angle`, `Point`, `NoROI`. Polygon-like types add `mnCoordinates` (`[x y]` rows); points add `mfCoordinates`.

## Usage in this toolkit

`areafrac.m` loads a cell outline and converts it to a mask:

```matlab
sROI = ReadImageJROI('c38.roi');
T = struct2cell(sROI);
M = cell2mat(T(7));          % coordinates field
BW = roipoly(I, M(:,1), M(:,2));
```

For robustness, access the coordinates by name instead of by position: `sROI.mnCoordinates`.

## Files needed

None – self-contained (includes the helpers `listzipcontents_rois` and `CellFlatten` as nested functions).

## Requirements

MATLAB (zip handling uses the built-in Java classes).
