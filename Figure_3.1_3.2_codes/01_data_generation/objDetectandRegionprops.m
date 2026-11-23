function [statsout, LL]=objDetectandRegionprops(Im, sensitivity, mask, ThreshA, ThreshB, thresh, doPlot)
%provide Im, sensitivity, mask, ThreshA, ThreshB,u get back statsout
% doPlot (optional, default true): set false to skip the figure(3) display

if nargin < 7
    doPlot = true;
end

I3=Im; s=sensitivity;
T = adaptthresh(I3, s); 
BW2 = imbinarize(I3,T);

    se = strel('disk',1);BW2b=imfill(BW2,'holes');se2 = strel('disk',1);
    BW3=imerode(BW2b, se);BW4=imdilate(BW3, se2);BW5=imfill(BW4, 'holes');


 BW=mask/max(mask(:)); % to overlay IRM mask on TIRF
    bw=BW5.*BW;
   
        cc=bwconncomp(bw);
    
    stats = regionprops(cc,'all'); 
    
    sizestats=size(stats);
    if sizestats(1)>0 
        uc=0;
        for u=1:sizestats(1)
        IntPixels=stats(u).PixelIdxList;Int=mean(mean((I3(IntPixels))));
     
        stats(u).Intensity = Int;cen=stats(u).Centroid; 
        stats(u).XC=cen(1);stats(u).YC=cen(2);
        end
    end
    idx = find(([stats.Area] > ThreshA) & ([stats.Area] <ThreshB) & ([stats.Intensity] >thresh)); % THRESH A 
    BWw = ismember(labelmatrix(cc),idx); LL=bwlabeln(BWw);
     if doPlot
         figure (3); imshow(LL, []); colormap jet;  %title ("Labelled endosomes")
     end
     stats2 = regionprops(LL,'all');

       sizestats=size(stats2);
    if sizestats(1)>0 
        uc=0;
        for u=1:sizestats(1)
        IntPixels=stats2(u).PixelIdxList;Int=double(mean(mean((I3(IntPixels)))));
        totInt=double(sum(sum((I3(IntPixels)))));
        stats2(u).Intensity = Int; stats2(u).totIntensity = totInt;cen=stats2(u).Centroid; 
        stats2(u).XC=cen(1);stats2(u).YC=cen(2);
                [~,ind] = max(I3(IntPixels));      % Index of maximum intensity within the object
        maxPixel = IntPixels(ind);        % Linear index of brightest pixel
        stats2(u).maxPixelID = maxPixel;stats2(u).maxInt = max(I3(IntPixels));
        end
    end

    statsout=stats2;