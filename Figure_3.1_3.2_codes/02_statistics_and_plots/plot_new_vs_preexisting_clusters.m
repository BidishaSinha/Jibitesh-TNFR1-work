%% plot_new_vs_preexisting_clusters.m
% Separates the 84 TNFa "all clusters" into two groups by spatially matching
% them (nearest XC/YC, within the same CellID/SetNum/PlateNum) against the
% 25 "pre-existing" clusters:
%   - Matched  -> this cluster was already there before TNFa addition
%   - Unmatched -> this cluster only appears in the all-clusters run, i.e.
%                  it formed newly after TNFa addition
% Then compares region properties and curvature/tension behavior between
% "New" and "Pre-existing" clusters, both from the SAME (all-clusters) run.

clear; clc; close all;
if ~usejava('desktop') || ~feature('ShowFigureWindows')
    set(0,'DefaultFigureVisible','off');
end
set(0, 'DefaultAxesFontSize', 12, 'DefaultAxesFontName', 'Helvetica', ...
       'DefaultTextFontSize', 12, 'DefaultTextFontName', 'Helvetica', ...
       'DefaultAxesLineWidth', 1.0, 'DefaultLineLineWidth', 1.5, ...
       'DefaultAxesBox', 'on', 'DefaultAxesTickDir', 'out', ...
       'DefaultLegendFontSize', 10, 'DefaultLegendBox', 'off');

MATCH_THRESHOLD_PX = 15;  % comfortably above the observed max match distance (12.1 px)

tnfaAllFolder = '/Volumes/T7 Touch/Forcurvature/For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260812_203348';
tnfaPreFolder = '/Volumes/T7 Touch/Forcurvature/For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260813_174118';

cd(tnfaAllFolder);
outFolder = fullfile(tnfaAllFolder, sprintf('MATLAB_New_vs_PreExisting_%s', datestr(now,'yyyymmdd_HHMMSS')));
mkdir(outFolder);
fprintf('Saving figures to:\n  %s\n\n', outFolder);

colorNew = [0.85 0.33 0.10];   % orange -- newly formed
colorPre = [0.16 0.47 0.84];   % blue   -- pre-existing

%% ================= LOAD + SPATIALLY MATCH =================
cd(tnfaAllFolder);
Sall = load('AllCells_CurvatureTopology_TimeSeries.mat', 'Tcombined');
Tall = Sall.Tcombined;
Tall = Tall(strcmp(string(Tall.RegionType),'TNFR1_cluster'), :);

cd(tnfaPreFolder);
Spre = load('AllCells_CurvatureTopology_TimeSeries.mat', 'Tcombined');
Tpre = Spre.Tcombined;
Tpre = Tpre(strcmp(string(Tpre.RegionType),'TNFR1_cluster'), :);
cd(tnfaAllFolder);

nAll = height(Tall);
isMatched = false(nAll, 1);
matchDist = nan(nAll, 1);

for i = 1:height(Tpre)
    sameCell = Tall.CellID == Tpre.CellID(i) & Tall.SetNum == Tpre.SetNum(i) & Tall.PlateNum == Tpre.PlateNum(i);
    idxCand = find(sameCell & ~isMatched);
    if isempty(idxCand)
        fprintf('  WARNING: pre-existing cluster %d (cell %d/%d/%d) has no unmatched candidate in the all-clusters run.\n', ...
            i, Tpre.CellID(i), Tpre.SetNum(i), Tpre.PlateNum(i));
        continue
    end
    d = sqrt((Tall.XC(idxCand) - Tpre.XC(i)).^2 + (Tall.YC(idxCand) - Tpre.YC(i)).^2);
    [dmin, j] = min(d);
    if dmin <= MATCH_THRESHOLD_PX
        isMatched(idxCand(j)) = true;
        matchDist(idxCand(j)) = dmin;
    else
        fprintf('  WARNING: pre-existing cluster %d (cell %d/%d/%d) nearest candidate is %.1f px away (> %d px threshold) -- not matched.\n', ...
            i, Tpre.CellID(i), Tpre.SetNum(i), Tpre.PlateNum(i), dmin, MATCH_THRESHOLD_PX);
    end
end

nMatched = sum(isMatched);
nNew = sum(~isMatched);
fprintf('Matched (pre-existing) in all-clusters run: %d / %d (expected %d)\n', nMatched, nAll, height(Tpre));
fprintf('New (unmatched) in all-clusters run: %d / %d\n', nNew, nAll);
fprintf('Match distances: median=%.1f px, max=%.1f px\n\n', median(matchDist(isMatched)), max(matchDist(isMatched)));

TNew = Tall(~isMatched, :);
TPre = Tall(isMatched, :);

%% ================= COMPARISON PLOTS: New vs. Pre-existing =================
fprintf('--- New vs. pre-existing clusters, region properties + behavior ---\n');

twoGroupBox(TNew.Area, TPre.Area, 'New','Pre-existing', ...
    'Cluster area: new vs. pre-existing', 'Area (px^2)', 'Q1_Area_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.Circularity, TPre.Circularity, 'New','Pre-existing', ...
    'Circularity: new vs. pre-existing', 'Circularity', 'Q2_Circularity_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.Eccentricity, TPre.Eccentricity, 'New','Pre-existing', ...
    'Eccentricity: new vs. pre-existing', 'Eccentricity', 'Q3_Eccentricity_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.MajorAxisLength, TPre.MajorAxisLength, 'New','Pre-existing', ...
    'Major axis length: new vs. pre-existing', 'Major axis length (px)', 'Q4_MajorAxis_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.MeanIntensity, TPre.MeanIntensity, 'New','Pre-existing', ...
    'Mean intensity: new vs. pre-existing', 'Mean intensity', 'Q5_MeanIntensity_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.MeanCurvature, TPre.MeanCurvature, 'New','Pre-existing', ...
    'Mean curvature: new vs. pre-existing', 'Mean curvature', 'Q6_MeanCurvature_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.Mean_FBR_SDt, TPre.Mean_FBR_SDt, 'New','Pre-existing', ...
    'FBR SDt: new vs. pre-existing', 'Mean FBR SDt', 'Q7_SDt_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.Mean_FBR_Tension, TPre.Mean_FBR_Tension, 'New','Pre-existing', ...
    'FBR Tension: new vs. pre-existing', 'Mean FBR Tension', 'Q8_Tension_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.SD_MeanCurvature_AllFrames, TPre.SD_MeanCurvature_AllFrames, 'New','Pre-existing', ...
    'SD of mean curvature: new vs. pre-existing', 'SD of mean curvature (2048 frames)', 'Q9_SDcurvature_new_vs_preexisting', outFolder, colorNew, colorPre);

twoGroupBox(TNew.FracClassChanges_AllFrames, TPre.FracClassChanges_AllFrames, 'New','Pre-existing', ...
    'Fraction of frames with a class change: new vs. pre-existing', 'Fraction of frames with a class change', ...
    'Q10_FracClassChanges_new_vs_preexisting', outFolder, colorNew, colorPre);

% Class mix comparison -- cell-level mean % +/- SEM, not just pooled, plus a
% per-class Mann-Whitney test (same convention as the rest of this session).
classOrder = {'CUP / PIT','TROUGH','SADDLE','RIDGE','DOME / HILL'};
classShort = {'CUP/PIT','TROUGH','SADDLE','RIDGE','DOME/HILL'};
nClass = numel(classOrder);
pooledNew = classPctVector(string(TNew.Classification), classOrder);
pooledPre = classPctVector(string(TPre.Classification), classOrder);

[pctNew, semNew, ~, ~, pctMatNew] = classPercentBySEM(string(TNew.Classification), TNew.CellID, classOrder);
[pctPre, semPre, ~, ~, pctMatPre] = classPercentBySEM(string(TPre.Classification), TPre.CellID, classOrder);

classPvals = nan(1,nClass);
for c = 1:nClass
    v1 = pctMatNew(:,c); v1 = v1(~isnan(v1));
    v2 = pctMatPre(:,c); v2 = v2(~isnan(v2));
    if numel(v1) >= 3 && numel(v2) >= 3
        classPvals(c) = ranksum(v1, v2);
    end
end
fprintf('  Class mix significance (Mann-Whitney on per-cell %%, New vs. Pre-existing):\n');
for c = 1:nClass
    fprintf('    %-12s p=%.3g %s\n', classShort{c}, classPvals(c), pToStars(classPvals(c)));
end

groupedBarTwoSeries(pctNew, semNew, pctPre, semPre, classShort, ...
    sprintf('New (n=%d)',nNew), sprintf('Pre-existing (n=%d)',nMatched), ...
    'Class mix: new vs. pre-existing (mean % +/- SEM over cells)', '% of clusters', ...
    'Q11_classmix_new_vs_preexisting', outFolder, classPvals);
fprintf('  (pooled: New %s, Pre-existing %s)\n', mat2str(round(pooledNew,1)), mat2str(round(pooledPre,1)));

%% ================= R1-R10: does the SDt/Tension RELATIONSHIP itself differ, new vs. pre-existing? =================
% R7-R10 (intensity) are safe straight off Tall's own columns (Mean_FBR_SDt/
% Tension and MeanIntensity/TotalIntensity are all in the same T-table row).
% R1-R6 need NFlips, which only exists in Allstats' full time series, not the
% T-table -- so Allstats is flattened separately here, and the SAME spatial
% match against Tpre is re-run against ITS OWN XC/YC (rather than assuming
% row alignment with Tall, which flattenClusterStats does not guarantee).
fprintf('--- SDt/Tension vs. curvature/class-change/intensity, new vs. pre-existing ---\n');

scatterWithCorrTwoGroups(TNew.Mean_FBR_SDt, TNew.MeanIntensity, TPre.Mean_FBR_SDt, TPre.MeanIntensity, ...
    'New', 'Pre-existing', 'Mean FBR SDt', 'Mean intensity', ...
    'SDt vs. mean intensity: new vs. pre-existing', 'R7_SDt_vs_MeanIntensity_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(TNew.Mean_FBR_Tension, TNew.MeanIntensity, TPre.Mean_FBR_Tension, TPre.MeanIntensity, ...
    'New', 'Pre-existing', 'Mean FBR Tension', 'Mean intensity', ...
    'Tension vs. mean intensity: new vs. pre-existing', 'R8_Tension_vs_MeanIntensity_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(TNew.Mean_FBR_SDt, TNew.TotalIntensity, TPre.Mean_FBR_SDt, TPre.TotalIntensity, ...
    'New', 'Pre-existing', 'Mean FBR SDt', 'Total intensity', ...
    'SDt vs. total intensity: new vs. pre-existing', 'R9_SDt_vs_TotalIntensity_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(TNew.Mean_FBR_Tension, TNew.TotalIntensity, TPre.Mean_FBR_Tension, TPre.TotalIntensity, ...
    'New', 'Pre-existing', 'Mean FBR Tension', 'Total intensity', ...
    'Tension vs. total intensity: new vs. pre-existing', 'R10_Tension_vs_TotalIntensity_new_vs_preexisting', outFolder);

cd(tnfaAllFolder);
Sflat = load('AllCells_CurvatureTopology_TimeSeries.mat', 'Allstats');
Cflat = flattenClusterStatsWithXY(Sflat.Allstats);
fprintf('  Flattened Allstats: %d clusters (vs. %d in T-table -- some may differ due to failed/edge-case objects)\n', numel(Cflat), nAll);

xcF = [Cflat.XC]'; ycF = [Cflat.YC]'; cellF = [Cflat.CellIdx]'; setF = [Cflat.SetNum]'; plateF = [Cflat.PlateNum]';
isMatchedF = false(numel(Cflat), 1);
for i = 1:height(Tpre)
    sameCell = cellF == Tpre.CellID(i) & setF == Tpre.SetNum(i) & plateF == Tpre.PlateNum(i);
    idxCand = find(sameCell & ~isMatchedF);
    if isempty(idxCand); continue; end
    d = sqrt((xcF(idxCand) - Tpre.XC(i)).^2 + (ycF(idxCand) - Tpre.YC(i)).^2);
    [dmin, j] = min(d);
    if dmin <= MATCH_THRESHOLD_PX
        isMatchedF(idxCand(j)) = true;
    end
end
fprintf('  (Allstats-based match: %d pre-existing, %d new)\n', sum(isMatchedF), sum(~isMatchedF));

CNew = Cflat(~isMatchedF);
CPre = Cflat(isMatchedF);
SDtNew = [CNew.SDt]'; SDtPre = [CPre.SDt]';
TenNew = [CNew.Tension]'; TenPre = [CPre.Tension]';
SDcNew = [CNew.SD_MeanCurvature]'; SDcPre = [CPre.SD_MeanCurvature]';
FccNew = [CNew.FracClassChanges]'; FccPre = [CPre.FracClassChanges]';
NFlipsNew = [CNew.NFlips]'; NFlipsPre = [CPre.NFlips]';

scatterWithCorrTwoGroups(SDtNew, SDcNew, SDtPre, SDcPre, ...
    'New', 'Pre-existing', 'Mean FBR SDt', 'SD of mean curvature', ...
    'SDt vs. SD of curvature: new vs. pre-existing', 'R1_SDt_vs_SDcurvature_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(SDtNew, FccNew, SDtPre, FccPre, ...
    'New', 'Pre-existing', 'Mean FBR SDt', 'Fraction of frames with a class change', ...
    'SDt vs. fraction of class changes: new vs. pre-existing', 'R2_SDt_vs_FracClassChanges_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(SDtNew, NFlipsNew, SDtPre, NFlipsPre, ...
    'New', 'Pre-existing', 'Mean FBR SDt', 'Number of sign flips', ...
    'SDt vs. sign-flip frequency: new vs. pre-existing', 'R3_SDt_vs_NFlips_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(TenNew, SDcNew, TenPre, SDcPre, ...
    'New', 'Pre-existing', 'Mean FBR Tension', 'SD of mean curvature', ...
    'Tension vs. SD of curvature: new vs. pre-existing', 'R4_Tension_vs_SDcurvature_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(TenNew, FccNew, TenPre, FccPre, ...
    'New', 'Pre-existing', 'Mean FBR Tension', 'Fraction of frames with a class change', ...
    'Tension vs. fraction of class changes: new vs. pre-existing', 'R5_Tension_vs_FracClassChanges_new_vs_preexisting', outFolder);

scatterWithCorrTwoGroups(TenNew, NFlipsNew, TenPre, NFlipsPre, ...
    'New', 'Pre-existing', 'Mean FBR Tension', 'Number of sign flips', ...
    'Tension vs. sign-flip frequency: new vs. pre-existing', 'R6_Tension_vs_NFlips_new_vs_preexisting', outFolder);

fprintf('\nAll done. Figures saved to:\n  %s\n', outFolder);


%% ================= LOCAL HELPERS =================
function val = getFieldOrNaN(s, fieldName)
    if isfield(s, fieldName) && ~isempty(s.(fieldName))
        val = double(s.(fieldName));
    else
        val = NaN;
    end
end

function C = flattenClusterStatsWithXY(statsCell)
    % Same as flattenClusterStats used elsewhere this session, but also
    % keeps XC/YC so New/Pre-existing status can be determined directly on
    % this struct via the same spatial-match logic, instead of assuming row
    % alignment with the T-table (which flattenClusterStats does not
    % guarantee).
    C = struct('CellIdx',{}, 'SetNum',{}, 'PlateNum',{}, 'XC',{}, 'YC',{}, ...
        'MeanCurvature',{}, 'SD_MeanCurvature',{}, 'FracClassChanges',{}, ...
        'SDt',{}, 'Tension',{}, 'NFlips',{});
    idx = 0;
    for cellIdx = 1:numel(statsCell)
        entry = statsCell{cellIdx};
        while iscell(entry) && numel(entry) == 1
            entry = entry{1};
        end
        if isempty(entry) || ~isstruct(entry); continue; end
        for k = 1:numel(entry)
            s = entry(k);
            curv = double(s.CurvatureTimeSeries(:));
            if isempty(curv); continue; end

            signVec = sign(curv);
            zeroIdx = find(signVec == 0);
            if ~isempty(zeroIdx)
                nzIdx = find(signVec ~= 0);
                if isempty(nzIdx)
                    signVec(:) = 1;
                else
                    for zi = zeroIdx'
                        prevNZ = nzIdx(nzIdx < zi);
                        if ~isempty(prevNZ)
                            signVec(zi) = signVec(prevNZ(end));
                        else
                            signVec(zi) = signVec(nzIdx(1));
                        end
                    end
                end
            end
            nFlips = numel(find(diff(signVec) ~= 0));

            idx = idx + 1;
            C(idx).CellIdx  = cellIdx;
            C(idx).SetNum   = getFieldOrNaN(s, 'SetNum');
            C(idx).PlateNum = getFieldOrNaN(s, 'PlateNum');
            C(idx).XC       = getFieldOrNaN(s, 'XC');
            C(idx).YC       = getFieldOrNaN(s, 'YC');
            C(idx).MeanCurvature    = mean(curv);
            C(idx).SD_MeanCurvature = getFieldOrNaN(s, 'SD_MeanCurvature_AllFrames');
            C(idx).FracClassChanges = getFieldOrNaN(s, 'FracClassChanges_AllFrames');
            C(idx).SDt      = getFieldOrNaN(s, 'Mean_FBR_SDt');
            C(idx).Tension  = getFieldOrNaN(s, 'Mean_FBR_Tension');
            C(idx).NFlips   = nFlips;
        end
    end
end

function scatterWithCorrTwoGroups(xA, yA, xB, yB, nameA, nameB, xlab, ylab, ttl, fname, outFolder)
    xA = xA(:); yA = yA(:); xB = xB(:); yB = yB(:);
    validA = ~isnan(xA) & ~isnan(yA); xA = xA(validA); yA = yA(validA);
    validB = ~isnan(xB) & ~isnan(yB); xB = xB(validB); yB = yB(validB);
    colorA = [0.85 0.33 0.10]; colorB = [0.16 0.47 0.84];

    fig = figure('Color','w','Position',[100 100 660 480]); hold on;
    scatter(xA, yA, 22, 'filled', 'MarkerFaceColor', colorA, 'MarkerFaceAlpha', 0.45, 'HandleVisibility','off');
    scatter(xB, yB, 22, 'filled', 'MarkerFaceColor', colorB, 'MarkerFaceAlpha', 0.45, 'HandleVisibility','off');

    [rA, pA] = corr(xA, yA, 'Type','Spearman');
    [rB, pB] = corr(xB, yB, 'Type','Spearman');

    allX = [xA(:); xB(:)];
    xx = linspace(min(allX), max(allX), 50);
    lA = []; lB = [];
    if numel(xA) >= 2
        pfA = polyfit(xA, yA, 1);
        lA = plot(xx, polyval(pfA, xx), '-', 'Color', colorA, 'LineWidth', 2.2);
    end
    if numel(xB) >= 2
        pfB = polyfit(xB, yB, 1);
        lB = plot(xx, polyval(pfB, xx), '-', 'Color', colorB, 'LineWidth', 2.2);
    end

    xlabel(xlab); ylabel(ylab); title(ttl, 'Interpreter','none');
    legend([lA lB], { ...
        sprintf('%s: r=%.2f, p=%.2g (n=%d)', nameA, rA, pA, numel(xA)), ...
        sprintf('%s: r=%.2f, p=%.2g (n=%d)', nameB, rB, pB, numel(xB))}, ...
        'Location','best');

    pmwY = NaN; pmwX = NaN;
    if numel(yA) >= 3 && numel(yB) >= 3
        pmwY = ranksum(yA, yB);
    end
    if numel(xA) >= 3 && numel(xB) >= 3
        pmwX = ranksum(xA, xB);
    end
    annotation('textbox', [0.05 0.005 0.9 0.045], ...
        'String', sprintf('Mann-Whitney, %s vs. %s: x-variable p=%.3g %s   y-variable p=%.3g %s', ...
            nameA, nameB, pmwX, pToStars(pmwX), pmwY, pToStars(pmwY)), ...
        'EdgeColor','none', 'HorizontalAlignment','center', 'FontSize',8, 'Color',[0.4 0.4 0.4]);

    exportgraphics(fig, fullfile(outFolder, [fname '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(outFolder, [fname '.pdf']));
    savefig(fig, fullfile(outFolder, [fname '.fig']));
    close(fig);
    fprintf('  %-45s %s: r=%.2f p=%.2g (n=%d)   %s: r=%.2f p=%.2g (n=%d)   [MW x: p=%.3g, MW y: p=%.3g]\n', ...
        fname, nameA, rA, pA, numel(xA), nameB, rB, pB, numel(xB), pmwX, pmwY);
end

function stars = pToStars(p)
    if isnan(p)
        stars = '';
    elseif p < 0.001
        stars = '***';
    elseif p < 0.01
        stars = '**';
    elseif p < 0.05
        stars = '*';
    else
        stars = '';
    end
end

function [pctMean, pctSEM, pctPooled, nGroups, pctMatOut] = classPercentBySEM(labels, groupIDs, classOrder)
    labels = string(labels);
    groupIDs = double(groupIDs);
    groups = unique(groupIDs(~isnan(groupIDs)));
    nG = numel(groups);
    nC = numel(classOrder);
    pctMat = nan(nG, nC);
    for gi = 1:nG
        mask = groupIDs == groups(gi);
        n = sum(mask);
        if n == 0; continue; end
        for ci = 1:nC
            pctMat(gi,ci) = 100 * sum(labels(mask) == string(classOrder{ci})) / n;
        end
    end
    pctMean = mean(pctMat, 1, 'omitnan');
    pctSEM  = std(pctMat, 0, 1, 'omitnan') / sqrt(nG);
    pctPooled = classPctVector(labels, classOrder);
    nGroups = nG;
    pctMatOut = pctMat;
end

function groupedBarTwoSeries(pct1, sem1, pct2, sem2, labels, name1, name2, ttl, ylab, fname, outFolder, pvals)
    if nargin < 12
        pvals = [];
    end
    fig = figure('Color','w','Position',[100 100 700 460]); hold on;
    b = bar([pct1(:) pct2(:)], 'grouped');
    errorbar(b(1).XEndPoints, pct1(:), sem1(:), 'k.', 'LineWidth',1.2, 'CapSize',6, 'LineStyle','none');
    errorbar(b(2).XEndPoints, pct2(:), sem2(:), 'k.', 'LineWidth',1.2, 'CapSize',6, 'LineStyle','none');
    set(gca,'XTick',1:numel(labels),'XTickLabel',labels);
    ylabel(ylab); title(ttl, 'Interpreter','none');
    legend(b, {name1, name2}, 'Location','northoutside', 'Orientation','horizontal');
    if ~isempty(pvals)
        yl = ylim;
        ylim([yl(1), yl(2)*1.15]);
        yl = ylim;
        for k = 1:numel(pvals)
            topY = max(pct1(k)+sem1(k), pct2(k)+sem2(k));
            stars = pToStars(pvals(k));
            if isempty(stars); stars = 'ns'; end
            text(k, topY + 0.035*range(yl), stars, 'HorizontalAlignment','center', ...
                'FontWeight','bold', 'FontSize',10);
        end
    end
    exportgraphics(fig, fullfile(outFolder, [fname '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(outFolder, [fname '.pdf']));
    savefig(fig, fullfile(outFolder, [fname '.fig']));
    close(fig);
end

function pct = classPctVector(labels, classOrder)
    labels = string(labels);
    nC = numel(classOrder);
    pct = zeros(1,nC);
    for ci = 1:nC
        pct(ci) = 100 * sum(labels == string(classOrder{ci})) / numel(labels);
    end
end

function twoGroupBox(vals1, vals2, name1, name2, ttl, ylab, fname, outFolder, color1, color2)
    vals1 = vals1(~isnan(vals1)); vals2 = vals2(~isnan(vals2));
    if isempty(vals1) || isempty(vals2)
        fprintf('  %-45s skipped -- one group is empty (n1=%d, n2=%d)\n', fname, numel(vals1), numel(vals2));
        return
    end
    allvals = [vals1(:); vals2(:)];
    grp = [repmat({name1}, numel(vals1),1); repmat({name2}, numel(vals2),1)];
    fig = figure('Color','w','Position',[100 100 600 460]);
    b = boxplot(allvals, grp, 'Colors', [color1; color2], 'symbol','r+');
    set(b,'LineWidth',1.3);
    q = quantile(allvals, [0.25 0.75]);
    iqr_ = diff(q);
    hiWhisker = q(2) + 1.5*iqr_;
    loWhisker = q(1) - 1.5*iqr_;
    ymax = min(max(allvals), hiWhisker*1.3);
    ymin = max(min(allvals), loWhisker*1.3);
    if ymin == ymax; ymin = ymin-1; ymax = ymax+1; end
    ylim([min(ymin,0), ymax]);
    ylabel(ylab); title(ttl, 'Interpreter','none');
    p = ranksum(vals1, vals2);
    text(0.02, 0.96, sprintf('Mann-Whitney p=%.2g, n1=%d, n2=%d', p, numel(vals1), numel(vals2)), ...
        'Units','normalized', 'FontWeight','bold', 'VerticalAlignment','top');
    exportgraphics(fig, fullfile(outFolder, [fname '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(outFolder, [fname '.pdf']));
    savefig(fig, fullfile(outFolder, [fname '.fig']));
    close(fig);
    fprintf('  %-45s p=%.2g\n', fname, p);
end
