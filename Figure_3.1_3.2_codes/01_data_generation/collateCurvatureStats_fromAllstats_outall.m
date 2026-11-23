function stats = collateCurvatureStats_fromAllstats_outall(Allstats, outall)

rows = [];
row = 0;

for i = 1:numel(Allstats)

    if isempty(Allstats{i})
        continue
    end

    statsCell = Allstats{i};

    for k = 1:numel(statsCell)

        if size(outall,1) < i || size(outall,2) < k
            continue
        end

        if ~isstruct(outall{i,k})
            continue
        end

        obj = statsCell(k);
        C   = outall{i,k};

        row = row + 1;

        rows(row).CellID = i;
        rows(row).ObjectID = k;
        rows(row).SetNum = getFieldOrNaN(obj,'SetNum');
        rows(row).PlateNum = getFieldOrNaN(obj,'PlateNum');

        rows(row).Area = getFieldOrNaN(obj,'Area');
        rows(row).MeanIntensity = getFieldOrNaN(obj,'Intensity');
        rows(row).TotalIntensity = getFieldOrNaN(obj,'totIntensity');
        rows(row).MaxIntensity = getFieldOrNaN(obj,'maxInt');

        rows(row).Mean_FBR_SD = getFieldOrNaN(obj,'Mean_FBR_SD');
        rows(row).Median_FBR_SD = getFieldOrNaN(obj,'Median_FBR_SD');
        rows(row).Mean_FBR_SDt = getFieldOrNaN(obj,'Mean_FBR_SDt');
        rows(row).Median_FBR_SDt = getFieldOrNaN(obj,'Median_FBR_SDt');
        rows(row).Mean_FBR_Tension = getFieldOrNaN(obj,'Mean_FBR_Tension');
        rows(row).Median_FBR_Tension = getFieldOrNaN(obj,'Median_FBR_Tension');
        rows(row).N_FBRs_overlap = getFieldOrNaN(obj,'N_FBRs_overlap');
        rows(row).N_FBRs_with_Tension = getFieldOrNaN(obj,'N_FBRs_with_Tension');

        % Whole-time-window (all-frames) topology consistency metrics
        rows(row).Mean_MeanCurvature_AllFrames = getFieldOrNaN(obj,'Mean_MeanCurvature_AllFrames');
        rows(row).SD_MeanCurvature_AllFrames   = getFieldOrNaN(obj,'SD_MeanCurvature_AllFrames');
        rows(row).SD_ClassCode_AllFrames       = getFieldOrNaN(obj,'SD_ClassCode_AllFrames');
        rows(row).NumClassChanges_AllFrames    = getFieldOrNaN(obj,'NumClassChanges_AllFrames');
        rows(row).FracClassChanges_AllFrames   = getFieldOrNaN(obj,'FracClassChanges_AllFrames');
        rows(row).SD_ClassChanges_AllFrames    = getFieldOrNaN(obj,'SD_ClassChanges_AllFrames');

        % Curvature from the single grand-mean image (only present in runs that
        % compute it, e.g. the 64-frame-block-averaged variant; NaN/missing otherwise)
        rows(row).GrandMeanFrame_MeanCurvature     = getFieldOrNaN(obj,'GrandMeanFrame_meanCurvature');
        rows(row).GrandMeanFrame_GaussianCurvature = getFieldOrNaN(obj,'GrandMeanFrame_gaussianCurvature');
        rows(row).GrandMeanFrame_ShapeIndex        = getFieldOrNaN(obj,'GrandMeanFrame_shapeIndex');
        rows(row).GrandMeanFrame_Curvedness        = getFieldOrNaN(obj,'GrandMeanFrame_curvedness');
        if isfield(obj,'GrandMeanFrame_classification') && ~isempty(obj.GrandMeanFrame_classification)
            rows(row).GrandMeanFrame_Classification = string(obj.GrandMeanFrame_classification);
        else
            rows(row).GrandMeanFrame_Classification = "missing";
        end

        rows(row).XC = getFieldOrNaN(obj,'XC');
        rows(row).YC = getFieldOrNaN(obj,'YC');

        % Remaining scalar regionprops shape descriptors (Area, Intensity-based
        % fields, XC/YC already captured above)
        rows(row).Circularity = getFieldOrNaN(obj,'Circularity');
        rows(row).Eccentricity = getFieldOrNaN(obj,'Eccentricity');
        rows(row).EquivDiameter = getFieldOrNaN(obj,'EquivDiameter');
        rows(row).EulerNumber = getFieldOrNaN(obj,'EulerNumber');
        rows(row).Extent = getFieldOrNaN(obj,'Extent');
        rows(row).MajorAxisLength = getFieldOrNaN(obj,'MajorAxisLength');
        rows(row).MinorAxisLength = getFieldOrNaN(obj,'MinorAxisLength');
        rows(row).Orientation = getFieldOrNaN(obj,'Orientation');
        rows(row).Perimeter = getFieldOrNaN(obj,'Perimeter');
        rows(row).Solidity = getFieldOrNaN(obj,'Solidity');
        rows(row).ConvexArea = getFieldOrNaN(obj,'ConvexArea');
        rows(row).FilledArea = getFieldOrNaN(obj,'FilledArea');
        rows(row).MaxFeretDiameter = getFieldOrNaN(obj,'MaxFeretDiameter');
        rows(row).MinFeretDiameter = getFieldOrNaN(obj,'MinFeretDiameter');
        rows(row).MaxFeretAngle = getFieldOrNaN(obj,'MaxFeretAngle');
        rows(row).MinFeretAngle = getFieldOrNaN(obj,'MinFeretAngle');

        if isfield(obj,'BoundingBox') && numel(obj.BoundingBox)==4
            bbox = obj.BoundingBox;
            rows(row).BBox_X = bbox(1);
            rows(row).BBox_Y = bbox(2);
            rows(row).BBox_Width = bbox(3);
            rows(row).BBox_Height = bbox(4);
        else
            rows(row).BBox_X = NaN;
            rows(row).BBox_Y = NaN;
            rows(row).BBox_Width = NaN;
            rows(row).BBox_Height = NaN;
        end

        rows(row).k1 = getFieldOrNaN(C,'k1');
        rows(row).k2 = getFieldOrNaN(C,'k2');
        rows(row).MeanCurvature = getFieldOrNaN(C,'meanCurvature');
        rows(row).GaussianCurvature = getFieldOrNaN(C,'gaussianCurvature');
        rows(row).Curvedness = getFieldOrNaN(C,'curvedness');
        rows(row).SignedCurvedness = getFieldOrNaN(C,'signedCurvedness');
        rows(row).ShapeIndex = getFieldOrNaN(C,'shapeIndex');
        rows(row).CentreHeight = getFieldOrNaN(C,'centreHeight');
        rows(row).NeighbourMean = getFieldOrNaN(C,'neighbourMean');
        rows(row).DeltaCentreNeighbour = getFieldOrNaN(C,'deltaCentreNeighbour');

        if isfield(C,'classification')
            rows(row).Classification = string(C.classification);
        else
            rows(row).Classification = "missing";
        end

        if isfield(C,'simpleClassification')
            rows(row).SimpleClassification = string(C.simpleClassification);
        else
            rows(row).SimpleClassification = "missing";
        end

        if isfield(C,'goodness')
            rows(row).RMSE = getFieldOrNaN(C.goodness,'RMSE');
            rows(row).R2 = getFieldOrNaN(C.goodness,'R2');
            rows(row).AdjustedR2 = getFieldOrNaN(C.goodness,'adjustedR2');
            rows(row).ToleranceUsed = getFieldOrNaN(C.goodness,'toleranceUsed');
        else
            rows(row).RMSE = NaN;
            rows(row).R2 = NaN;
            rows(row).AdjustedR2 = NaN;
            rows(row).ToleranceUsed = NaN;
        end
    end
end

T = struct2table(rows);
stats.objectTable = T;

end

function val = getFieldOrNaN(S, fname)
if isstruct(S) && isfield(S,fname) && ~isempty(S.(fname))
    val = S.(fname);
    if isstring(val) || ischar(val)
        return
    end
    if numel(val) > 1
        val = mean(val(:),'omitnan');
    end
else
    val = NaN;
end
end