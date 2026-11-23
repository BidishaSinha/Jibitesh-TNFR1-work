function statsout = addFBR_values_to_objects(statsbefwithOV, FBR, SDs, SDt, fbrTen, imageSize)

statsout = statsbefwithOV;



for k = 1:numel(statsout)

   if ~isstruct(statsbefwithOV)
    continue
    end

    pix = statsout(k).PixelIdxList;
    [rowPix, colPix] = ind2sub(imageSize, pix);

    objectFBRs = [];

    for f = 1:size(FBR,1)

        y0 = FBR(f,1);
        x0 = FBR(f,2);
        w  = FBR(f,3);
        h  = FBR(f,4);

        inside = colPix >= x0 & colPix <= x0+w-1 & ...
                 rowPix >= y0 & rowPix <= y0+h-1;

        if any(inside)
            objectFBRs(end+1) = f;
        end
    end

    objectFBRs = unique(objectFBRs);

    statsout(k).FBR_IDs = objectFBRs;
    statsout(k).N_FBRs_overlap = numel(objectFBRs);

    sdVals  = nan(size(objectFBRs));
    sdtVals = nan(size(objectFBRs));
    tenVals = nan(size(objectFBRs));

    for q = 1:numel(objectFBRs)

        fbrID = objectFBRs(q);

        idxSDs = SDs(:,1) == fbrID;
        if any(idxSDs)
            sdVals(q) = mean(SDs(idxSDs,2), 'omitnan');
        end

        idxSDt = SDt(:,1) == fbrID;
        if any(idxSDt)
            sdtVals(q) = mean(SDt(idxSDt,2), 'omitnan');
        end

        idxTen = fbrTen(:,1) == fbrID;
        if any(idxTen)
            tenVals(q) = mean(fbrTen(idxTen,2), 'omitnan');
        else
            tenVals(q) = NaN;
        end
    end

    statsout(k).FBR_SD_values = sdVals;
    statsout(k).Mean_FBR_SD = mean(sdVals, 'omitnan');
    statsout(k).Median_FBR_SD = median(sdVals, 'omitnan');

    statsout(k).FBR_SDt_values = sdtVals;
    statsout(k).Mean_FBR_SDt = mean(sdtVals, 'omitnan');
    statsout(k).Median_FBR_SDt = median(sdtVals, 'omitnan');

    statsout(k).FBR_Tension_values = tenVals;
    statsout(k).Mean_FBR_Tension = mean(tenVals, 'omitnan');
    statsout(k).Median_FBR_Tension = median(tenVals, 'omitnan');

    statsout(k).N_FBRs_with_Tension = sum(~isnan(tenVals));
end

end