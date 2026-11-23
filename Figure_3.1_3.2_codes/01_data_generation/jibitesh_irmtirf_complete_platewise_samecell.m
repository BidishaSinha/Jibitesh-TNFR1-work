%This code assume SetN>condition>IRM data and
%SetN>condition>condition>fluorescence data (lower sorted .tif: first
%movie; higher sorted .tif: later movie
% functions that will be used: 
% 1. objDetectandRegionprops(Im, sensitivity, mask, ThreshA, ThreshB, statsout)
% 2. out = curvature5x5_fit(Z, dx)
clear
close all
runTimestamp = char(datetime('now','Format','yyyyMMdd_HHmmss')); % unique per run so output folders never overwrite a previous run
% folder ='/Volumes/T7 Touch/Forcurvature/Set1/control';
% folder2='/Volumes/T7 Touch/Forcurvature/Set1/control/control';
% rootFolder = '/Volumes/T7 Touch/Forcurvature/Set1/control';

folder ='/Volumes/T7 Touch/Forcurvature/with_good_cells/set5/Plate1/Exported'; %BAA
folder2='/Volumes/T7 Touch/Forcurvature/with_good_cells/set5/Plate1/Exported/Before_After/001';
rootFolder ='/Volumes/T7 Touch/Forcurvature/with_good_cells/set5/Plate1/Exported';%IRM


% % get BAAA files
 files = dir(fullfile(folder, 'BAAA*.mat'));
% nFiles = numel(files);
% fprintf('Number of .mat files starting with "BAAA": %d\n', nFiles);
%%
ii=0;
for j=1:3
if j==1 jj=5;
    ncells=5;
elseif j==2 jj=6;
    ncells=8;
elseif j==3 jj=7;
    ncells = 8;
end



for i=1: ncells
    ii=ii+1;

rootFolder = sprintf('/Volumes/T7 Touch/Forcurvature/with_good_cells/set%d/Plate%d/Exported', jj,i);
folder  = rootFolder;
folder2 = sprintf('/Volumes/T7 Touch/Forcurvature/with_good_cells/set%d/Plate%d/Exported/Before_After/001', jj,i);





    close all
    clearvars -except files nFiles folder folder2 rootFolder i ii j jj Allstats outall ncells runTimestamp AllRandomStats outallRandom
    sensitivity = 0.25; ThreshA=10; ThreshB=5000; thresh=200;
    matFile = files(1).name;
    matPath = fullfile(folder, matFile);

load(matPath);
mask=(65535-IrgbM(:,:,1)).*(65535-IrgbM(:,:,2)); % IRM mask from BAA file

%% Tif files being hunted out


I = imread(fullfile(folder2, "001.tif"));
% Ibeforeall = zeros(size(I,1),size(I,2),numel(beforeFiles),class(I)); % when
% all frames are needed
Ibeforeall = zeros(size(I,1),size(I,2),1,class(I));% first and last frame only

% for k = 1:numel(beforeFiles)
    Ibeforeall(:,:,1) = I;

% end

%% Read all TIFFs from secondFolder/set


I = imread(fullfile(folder2, "002.tif"));

Iafterall = zeros(size(I,1),size(I,2),1,class(I)); % first and last frame only

% for k = 1:numel(afterFiles)
    Iafterall(:,:,1) = I;
    
% end
%% Object detection

pixelSize=65;
Ibefore=Ibeforeall(:,:,end);
Iafter=Iafterall(:,:,1);
Ibeforefirst=Ibeforeall(:,:,1);

%call function to detect object from the last frame of first movie

I1last=Ibefore(xstart:xend, ystart:yend, end);

% [statsbef, LLbefore, BWfinalbeforelast, IblobMax1, scaleMap1] = objDetect_MultiLoG(I1last, mask, ThreshA, ThreshB) ;

[statsbef, LLbefore]=objDetectandRegionprops(I1last, sensitivity, mask, ThreshA, ThreshB, thresh);
figure(15); subplot(2,4,1);imshow(I1last, []);  title ("Before image-last frame")
figure(15); subplot(2,4,2);imshow(LLbefore, []); colormap jet;  title ("Before objects")

Objbefore=LLbefore;
Objbefore(Objbefore>1) =1;

%call function to detect object from the first frame of first movie

I1first=Ibeforefirst(xstart:xend, ystart:yend);
% [statsbef1, LLbefore1, BWfinalbefore1, IblobMax2, scaleMap2] = objDetect_MultiLoG(I1first, mask, ThreshA, ThreshB);
[statsbef1, LLbefore1]=objDetectandRegionprops(I1first, sensitivity, mask, ThreshA, ThreshB, thresh);
figure(15); subplot(2,4,3);imshow(I1first, []);  title ("Before image-first frame")
figure(15); subplot(2,4,4); imshow(LLbefore1, []); colormap jet;  title ("Before objects from first frame")
Objbefore1=LLbefore1;
Objbefore1(Objbefore1>1) =1;


%calculate object lifetimes from the last frame of first movie


% Allstats{ii}=stats2;
%call function to detect object from the first frame of second movie

 I2first=Iafter(xstart:xend, ystart:yend);
% [statsaf, LLafter, BWfinalafter IblobMax3, scaleMap3] = objDetect_MultiLoG(I2first, mask, ThreshA, ThreshB);
[statsaf, LLafter]=objDetectandRegionprops(I2first, sensitivity, mask, ThreshA, ThreshB, thresh);
figure(15); subplot(2,4,5);imshow(I2first, []);  title ("After image-first frame")
figure(15); subplot(2,4,6); imshow(LLafter, []); colormap jet;  title ("After objects")

Objafter=LLafter;
Objafter(Objafter>1) =1;


%call function to detect overlapping objects



npbefore=size(statsbef,1);c=0;
for j=1:npbefore
idxbef=statsbef(j).PixelIdxList;
areabef=statsbef(j).Area;
checkarea=max(9,areabef/10); % either overlap is of 9 pixels or 1/10th of the original area whichever is maximum
s=sum(sum(Objafter(idxbef))); s2=sum(sum(Objbefore1(idxbef)));
 if s>checkarea && s2>areabef*0.65 % here we are checking if objects in last frame of first movie have atleast solight overlap woth first frame of second movie and good overlap with first movies first frame
% if s2>areabef*0.65    
    c=c+1;
    statsbefwithOV(c)=statsbef(j);

end
end

Overlapregions=zeros(size(LLbefore));
if c>0
for k = 1:numel(statsbefwithOV)
    Overlapregions(statsbefwithOV(k).PixelIdxList)=1;
end
else
    statsbefwithOV(1)={0};
end

Irgboverlap(:,:,1)=LLbefore;
Irgboverlap(:,:,2)=LLafter;
Irgboverlap(:,:,3)=Overlapregions;

figure(15); subplot(2,4,7); imshow(Irgboverlap, []);title("overlap");



%use last frame of first movie and centrroids of stuck puncta to get FBR
%ten and SDs, sdt data



%% Read corresponding IRM data

% Root folder


% Get all subfolders
d = dir(rootFolder);
d = d([d.isdir]);
d = d(~ismember({d.name},{'.','..'}));

% Keep only folders with numeric names (001,002,...)
isNum = cellfun(@(x) ~isempty(regexp(x,'^\d+$','once')), {d.name});
d = d(isNum);

% Sort numerically
folderNums = cellfun(@str2double,{d.name});
[~,idx] = sort(folderNums);
d = d(idx);

% Read the i-th folder
      % change as needed

folderi = fullfile(rootFolder,d(1).name);
setFolder = fullfile(folderi,'set');

%%  Read all tif files (frame list) from the IRM time series

tifFiles = dir(fullfile(setFolder,'*.tif'));
[~,idx] = sort({tifFiles.name});
tifFiles = tifFiles(idx);
nFrames = numel(tifFiles);

I0 = imread(fullfile(setFolder,tifFiles(1).name));


I=imread(fullfile(setFolder,tifFiles(1).name));I=I(xstart:xend, ystart:yend);
figure(15); subplot(2,4,8);imshow(I, []); colormap jet;  title ("IRM")

% Irgboverlap2(:,:,1)=I;
% Irgboverlap2(:,:,2)=double(max(I(:)))*Overlapregions+double(min(min(I(:))));
% Irgboverlap2(:,:,3)=double(max(I(:)))*Overlapregions+double(min(min(I(:))));

Ishow = mat2gray(double(I), prctile(double(I(:)), [1 99]));
objMask = Overlapregions == 1;
RGB = repmat(Ishow, [1 1 3]);
alpha = 0.6;   % increase for stronger red overlay

RGB(:,:,3) = RGB(:,:,1) .* (~objMask) + ...
             (1-alpha)*RGB(:,:,1).*objMask;
RGB(:,:,2) = RGB(:,:,1) .* (~objMask) + ...
             (1-alpha)*RGB(:,:,1).*objMask;
RGB(:,:,1) = RGB(:,:,3) .* (~objMask) + ...
             ((1-alpha)*RGB(:,:,3) + alpha).*objMask;

figure(16); imshow(RGB);   title('IRM with red object overlay');

%% Curvature & classification across the full IRM time series (all nFrames)
% Same (row,col) position is used for every frame, per cluster, since the
% position comes from the reference "before" object detection - this
% tracks topology (curvature + classification) of the SAME cluster over
% the whole imaging window instead of just the first frame.
%
% Alongside every detected/overlapping TNFR1 cluster, an equal number of
% random control points is also picked - anywhere TNFR1 has NOT been
% detected as clustered in ANY of the three detection passes (before-last,
% before-first, after-first), with a 5px buffer around every detected
% object and a minimum 10px separation between the random points
% themselves - so the same whole-window curvature/classification analysis
% can be compared between real clusters and random background.

classNames = ["FLAT","CUP / PIT","TROUGH","SADDLE","RIDGE","DOME / HILL"];
classCodes = [0 1 2 3 4 5];

if c>0
    nClust = numel(statsbefwithOV);

    clustRow = nan(nClust,1);
    clustCol = nan(nClust,1);
    for k = 1:nClust
        pixelID = statsbefwithOV(k).maxPixelID;
        [r0,c0] = ind2sub(size(I), pixelID);
        clustRow(k) = r0;
        clustCol(k) = c0;
    end
else
    nClust = 0;
    clustRow = [];
    clustCol = [];
end

%% Random background control points, avoiding every detected object
rng('shuffle');

objectMask = false(size(I));
if exist('Objbefore','var'),  objectMask = objectMask | (Objbefore>0);  end
if exist('Objbefore1','var'), objectMask = objectMask | (Objbefore1>0); end
if exist('Objafter','var'),   objectMask = objectMask | (Objafter>0);   end
objectMaskBuffered = imdilate(objectMask, strel('disk',5));

validBackground = (mask>0) & ~objectMaskBuffered;
validBackground(1:2,:) = false; validBackground(end-1:end,:) = false;
validBackground(:,1:2) = false; validBackground(:,end-1:end) = false;

[bgRows, bgCols] = find(validBackground);

nRandomTarget = 5 * nClust; % 5x as many random background points as real, overlap-confirmed clusters in this cell
minSep = 10;                % minimum center-to-center pixel separation between chosen random points

randRow = nan(nRandomTarget,1);
randCol = nan(nRandomTarget,1);
nRandomActual = 0;
attempts = 0;
maxAttempts = max(8000, 300*nRandomTarget); % scale the attempt budget with the larger target

while nRandomActual < nRandomTarget && attempts < maxAttempts && ~isempty(bgRows)
    attempts = attempts + 1;
    pick = randi(numel(bgRows));
    rr = bgRows(pick); cc = bgCols(pick);

    if nRandomActual > 0
        dPrev = sqrt((randRow(1:nRandomActual)-rr).^2 + (randCol(1:nRandomActual)-cc).^2);
        if any(dPrev < minSep)
            continue
        end
    end

    nRandomActual = nRandomActual + 1;
    randRow(nRandomActual) = rr;
    randCol(nRandomActual) = cc;
end

randRow = randRow(1:nRandomActual);
randCol = randCol(1:nRandomActual);

%% Combined position list: real clusters first, random control points after
nTotal = nClust + nRandomActual;
allRow = [clustRow; randRow];
allCol = [clustCol; randCol];

meanCurvatureTS  = nan(nTotal, nFrames);
gaussCurvatureTS = nan(nTotal, nFrames);
shapeIndexTS     = nan(nTotal, nFrames);
curvednessTS     = nan(nTotal, nFrames);
classCodeTS      = nan(nTotal, nFrames);
classificationTS = strings(nTotal, nFrames);

if nTotal > 0
    for f = 1:nFrames

        Iframe = imread(fullfile(setFolder, tifFiles(f).name));
        Iframe = Iframe(xstart:xend, ystart:yend);

        for k = 1:nTotal
            r0 = allRow(k); c0 = allCol(k);

            if r0-2<1 || r0+2>size(Iframe,1) || c0-2<1 || c0+2>size(Iframe,2)
                continue % patch would fall outside the cropped frame
            end

            patch5x5 = double(Iframe(r0-2:r0+2, c0-2:c0+2))/35.625;
            outF = curvature5x5_cubicFit(patch5x5, 65);

            meanCurvatureTS(k,f)  = outF.meanCurvature;
            gaussCurvatureTS(k,f) = outF.gaussianCurvature;
            shapeIndexTS(k,f)     = outF.shapeIndex;
            curvednessTS(k,f)     = outF.curvedness;
            classificationTS(k,f) = string(outF.classification);
            classCodeTS(k,f)      = classCodes(classNames == string(outF.classification));

            if f==1
                if k<=nClust
                    outall{ii, k} = outF; % first-frame result, kept for the existing object-table pipeline
                else
                    outallRandom{ii, k-nClust} = outF; % first-frame result for the matching random control point
                end
            end
        end

        if mod(f,200)==0 || f==nFrames
            fprintf('  cell %d: curvature computed for frame %d/%d (%d real + %d random points)\n', ...
                ii, f, nFrames, nClust, nRandomActual);
        end
    end
end

for k = 1:nClust
    curveVec   = meanCurvatureTS(k,:);
    classVec   = classCodeTS(k,:);
    validClass = classVec(~isnan(classVec));
    changeFlags = diff(validClass) ~= 0;

    statsbefwithOV(k).CurvatureTimeSeries         = curveVec;
    statsbefwithOV(k).GaussianCurvatureTimeSeries = gaussCurvatureTS(k,:);
    statsbefwithOV(k).ShapeIndexTimeSeries         = shapeIndexTS(k,:);
    statsbefwithOV(k).CurvednessTimeSeries         = curvednessTS(k,:);
    statsbefwithOV(k).ClassificationTimeSeries     = classificationTS(k,:);
    statsbefwithOV(k).ClassCodeTimeSeries          = classVec;

    statsbefwithOV(k).Mean_MeanCurvature_AllFrames = mean(curveVec,'omitnan');
    statsbefwithOV(k).SD_MeanCurvature_AllFrames   = std(curveVec,'omitnan');

    statsbefwithOV(k).SD_ClassCode_AllFrames     = std(validClass,'omitnan');
    statsbefwithOV(k).NumClassChanges_AllFrames  = sum(changeFlags);
    statsbefwithOV(k).FracClassChanges_AllFrames = mean(changeFlags);
    statsbefwithOV(k).SD_ClassChanges_AllFrames  = std(double(changeFlags),'omitnan');
end

if nRandomActual > 0
    for m = 1:nRandomActual
        k = nClust + m;
        curveVec   = meanCurvatureTS(k,:);
        classVec   = classCodeTS(k,:);
        validClass = classVec(~isnan(classVec));
        changeFlags = diff(validClass) ~= 0;

        RandomPts(m).RandomID = m;
        RandomPts(m).XC = randCol(m);
        RandomPts(m).YC = randRow(m);
        RandomPts(m).PixelIdxList = sub2ind(size(I), randRow(m), randCol(m)); % single-pixel "footprint", needed by addFBR_values_to_objects below

        RandomPts(m).CurvatureTimeSeries         = curveVec;
        RandomPts(m).GaussianCurvatureTimeSeries = gaussCurvatureTS(k,:);
        RandomPts(m).ShapeIndexTimeSeries         = shapeIndexTS(k,:);
        RandomPts(m).CurvednessTimeSeries         = curvednessTS(k,:);
        RandomPts(m).ClassificationTimeSeries     = classificationTS(k,:);
        RandomPts(m).ClassCodeTimeSeries          = classVec;

        RandomPts(m).Mean_MeanCurvature_AllFrames = mean(curveVec,'omitnan');
        RandomPts(m).SD_MeanCurvature_AllFrames   = std(curveVec,'omitnan');

        RandomPts(m).SD_ClassCode_AllFrames     = std(validClass,'omitnan');
        RandomPts(m).NumClassChanges_AllFrames  = sum(changeFlags);
        RandomPts(m).FracClassChanges_AllFrames = mean(changeFlags);
        RandomPts(m).SD_ClassChanges_AllFrames  = std(double(changeFlags),'omitnan');
    end
else
    RandomPts = {0};
    outallRandom{ii, 1} = {0};
end

if c==0
    outall{ii, 1}={0};
end

%% Adding Sd and fbrten values

statsbefwithOV = addFBR_values_to_objects( ...
    statsbefwithOV, FBR, SDs, SDt, fbrTen, size(I));

% Same FBR-based SD/SDt/Tension lookup applied to the random background
% points, using each point's single-pixel PixelIdxList, so RandomPts carries
% the same Mean/Median_FBR_SD/SDt/Tension fields as the real clusters do.
if nRandomActual > 0
    RandomPts = addFBR_values_to_objects( ...
        RandomPts, FBR, SDs, SDt, fbrTen, size(I));
end

if c>0
for k = 1:numel(statsbefwithOV)
    statsbefwithOV(k).SetNum = jj;
    statsbefwithOV(k).PlateNum = i;
end
Allstats{ii}=statsbefwithOV;
else
   statsbefwithOV={0};
    Allstats{ii}={0};
end

if nRandomActual > 0
    for m = 1:nRandomActual
        RandomPts(m).SetNum = jj;
        RandomPts(m).PlateNum = i;
    end
    AllRandomStats{ii} = RandomPts;
else
    RandomPts = {0};
    AllRandomStats{ii} = {0};
end


Ibeforeall=[];Iafterall=[];
[~, matBase] = fileparts(matFile);
fullpath = fullfile(folder, "withANALYSIS_" + matBase + sprintf("_set%d_Plate%d_", jj, i) + runTimestamp + ".mat");
save(fullpath, 'statsbefwithOV', 'RandomPts', 'c', 'jj', 'i', 'ii', 'rootFolder', '-v7.3');



end
end

% %%
% stats = collateCurvatureStats_fromAllstats_outall(Allstats, outall);
% T = stats.objectTable;
% 
% objectTable = stats.objectTable;
% cellTable = stats.cellTable;
% classSummary = stats.classSummary;
% summaryAcrossCells = stats.summaryAcrossCells;
% make/update mastertable


% writetable(stats.objectTable, 'curvature_object_level_stats.csv');
% writetable(stats.cellTable, 'curvature_cell_level_stats.csv');
% writetable(stats.classSummary, 'curvature_class_percentages.csv');
% writetable(stats.summaryAcrossCells, 'curvature_summary_across_cells.csv');

%%
stats = collateCurvatureStats_fromAllstats_outall(Allstats, outall);
T = stats.objectTable;

% Same collation applied to the random background control points, so
% clusters and random regions can be compared with identical columns.
statsRandom = collateCurvatureStats_fromAllstats_outall(AllRandomStats, outallRandom);
Trandom = statsRandom.objectTable;

T.RegionType = repmat("TNFR1_cluster", height(T), 1);
if height(Trandom) > 0
    Trandom.RegionType = repmat("Random_control", height(Trandom), 1);
    Tcombined = [T; Trandom];
else
    warning('No random control points were collected across any cell; Tcombined = T only.');
    Tcombined = T;
end

%% Save whole-window results (full per-frame arrays live in Allstats/AllRandomStats;
% T/Trandom carry the per-cluster summary columns, incl. SD_MeanCurvature_AllFrames
% and SD_ClassChanges_AllFrames)
% Folder name carries runTimestamp so a re-run never overwrites a previous run's results.
outputFolder = fullfile(folder, ['Curvature_Analysis_Output_' runTimestamp]);
if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end
save(fullfile(outputFolder,'AllCells_CurvatureTopology_TimeSeries.mat'), ...
     'Allstats','outall','T','AllRandomStats','outallRandom','Trandom','Tcombined','-v7.3');
writetable(T, fullfile(outputFolder,'curvature_object_level_stats.csv'));
writetable(T, fullfile(outputFolder,'Tnew_control.csv'));
writetable(Trandom, fullfile(outputFolder,'curvature_random_control_stats.csv'));
writetable(Tcombined, fullfile(outputFolder,'curvature_clusters_vs_random_combined.csv'));
% figure;
% 
% 
% %%
% collateCurvatureStats(outall)
% % [corrTable, classCorrTable] = plotCurvatureCorrelations(T);
% 
% stats = collateCurvatureStats_fromAllstats_outall(Allstats, outall);
% T = stats.objectTable;

% [corrTable, classCorrTable] = plotCurvatureCorrelations(T);

%%
%
corrOut = plotCurvatureCorrelations(T, folder, outputFolder);
%%
classStats = plotClasswiseStatistics(T, outputFolder);

%% Mirror this run into a stable "latest" folder alongside the timestamped archive.
% The timestamped outputFolder above is never touched again (permanent record of this
% run); latestFolder is overwritten every run so there's always one predictable place
% to find the most recent results without knowing the timestamp.
latestFolder = fullfile(folder, 'Curvature_Analysis_Output_latest');
if exist(latestFolder,'dir')
    rmdir(latestFolder,'s');
end
copyfile(outputFolder, latestFolder);


%%
%% ===========================================================
% Percentage of clusters belonging to each class (cell-wise)
%% ===========================================================

% if ~iscategorical(T.Classification)
%     T.Classification = categorical(string(T.Classification));
% end
% 
% classes = categories(T.Classification);
% 
% nCells = numel(Allstats);
% 
% percentPerCell = nan(nCells,numel(classes));
% 
% for i = 1:nCells
% 
%     if isempty(Allstats{i}) || ~isstruct(Allstats{i})
%         continue
%     end
% 
%     % Classes of all objects in this cell
%     classCell = strings(0);
% 
%     for k = 1:numel(Allstats{i})
% 
%         if k>size(outall,2)
%             continue
%         end
% 
%         if isempty(outall{i,k}) || iscell(outall{i,k})
%             continue
%         end
% 
%         classCell(end+1) = string(outall{i,k}.classification);
% 
%     end
% 
%     if isempty(classCell)
%         continue
%     end
% 
%     N = numel(classCell);
% 
%     for c = 1:numel(classes)
% 
%         percentPerCell(i,c) = ...
%             100*sum(classCell==classes{c})/N;
% 
%     end
% 
% end
% 
% meanPercent = mean(percentPerCell,1,'omitnan');
% semPercent  = std(percentPerCell,0,1,'omitnan')./ ...
%               sqrt(sum(~isnan(percentPerCell),1));
% 
% %Plot
% 
% fig = figure('Color','w','WindowState','maximized');
% 
% bar(meanPercent)
% hold on
% 
% errorbar(1:numel(classes),...
%          meanPercent,...
%          semPercent,...
%          'k.',...
%          'LineWidth',2)
% 
% set(gca,'XTick',1:numel(classes),...
%         'XTickLabel',classes,...
%         'FontSize',12)
% 
% ylabel('% of clusters')
% xlabel('Curvature class')
% figTitle='Percentage of clusters in each curvature class';title(figTitle)
% 
% grid on
% box off
% outputFolder = 'Curvature_Analysis_Output';
% pdfFile = fullfile(outputFolder,'Correlation_All_Figures.pdf');
% 
% %% Make a safe non-empty filename
% figTitle = char(string(figTitle));
% safeTitle = matlab.lang.makeValidName(figTitle);
% 
% if isempty(safeTitle)
%     safeTitle = 'CorrelationFigure';
% end
% 
% % Avoid very long filenames
% if numel(safeTitle) > 120
%     safeTitle = safeTitle(1:120);
% end
% 
% figName = char(fullfile(outputFolder, [safeTitle '.fig']));
% pngName = char(fullfile(outputFolder, [safeTitle '.png']));
% pdfFile = char(pdfFile);
% 
% disp(figName)   % optional debug line; remove later
% 
% savefig(fig, figName);
% exportgraphics(figHandle, pngName, 'Resolution', 300);
% exportgraphics(figHandle, pdfFile, 'Append', true);