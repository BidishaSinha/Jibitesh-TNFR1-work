% NOTE (Figure 3.1 package): only the two SETUP lines below (rawFolder, avgFolder) differ from the original file.
% The original pointed at the TNFa pre-existing-only run; Figure 3.1 panels a-f come from the CONTROL run below.
%% plot_all_curvature_analyses.m
% Reproduces, in native MATLAB, every analysis built as web charts this
% session: SDt/Tension correlations, class percentages + curvature-by-class
% (single-snapshot, majority-vote, global-average), TNFR1-vs-random-background
% comparison, sign-flip / time-between-flips / long-lived clusters, the full
% predictor correlation sweep, the class-transition network, class-range,
% and multi-step transition PATTERN probabilities (e.g. PIT -> SADDLE -> DOME/HILL).
%
% Run this whole file (F5), or run section-by-section with Ctrl+Enter.
% Figures are shown on screen (if a display is available) AND saved as
% .png + .fig into a timestamped folder next to the raw-run data.

clear; clc; close all;
if ~usejava('desktop') || ~feature('ShowFigureWindows')
    set(0,'DefaultFigureVisible','off');  % headless/batch runs only
end

% Manuscript-ready defaults, applied globally so every figure below inherits
% them without touching each individual plotting call. Explicit smaller
% FontSize overrides already in specific helpers (dense heatmap cell labels,
% the 20-category pair plots) are left as-is -- they take precedence over
% these defaults, which only fill in axis labels/titles/legends/ticks that
% aren't otherwise set.
set(0, 'DefaultAxesFontSize', 12, ...
       'DefaultAxesFontName', 'Helvetica', ...
       'DefaultTextFontSize', 12, ...
       'DefaultTextFontName', 'Helvetica', ...
       'DefaultAxesLineWidth', 1.0, ...
       'DefaultLineLineWidth', 1.5, ...
       'DefaultAxesBox', 'on', ...
       'DefaultAxesTickDir', 'out', ...
       'DefaultLegendFontSize', 10, ...
       'DefaultLegendBox', 'off');

%% ================= SETUP =================
% avgFolder is optional -- set to '' to skip Groups B5/B6/H/I/J (global-average
% classification and the clubbed-data comparisons), e.g. when only the raw run
% exists for this dataset so far.
rawFolder = '/Volumes/T7 Touch/Forcurvature/with_good_cells/set7/Plate8/Exported/Curvature_Analysis_Output_20260807_094538';
avgFolder = '';   % only needed for groups B5/B6/H/I/J, which Figure 3.1 does not use

cd(rawFolder);
outFolder = fullfile(rawFolder, sprintf('MATLAB_SessionAnalysis_%s', datestr(now,'yyyymmdd_HHMMSS')));
mkdir(outFolder);
fprintf('Saving all figures to:\n  %s\n\n', outFolder);

classOrder  = {'CUP / PIT','TROUGH','SADDLE','RIDGE','DOME / HILL'};
classShort  = {'CUP/PIT','TROUGH','SADDLE','RIDGE','DOME/HILL'};
nClass      = numel(classOrder);
classColors = [0.16 0.47 0.84; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.93 0.69 0.13; 0.49 0.18 0.56];

%% ================= PART 1: load RAW run (full 2048-frame time series) =================
cd(rawFolder);
S = load('AllCells_CurvatureTopology_TimeSeries.mat','Tcombined','Allstats','AllRandomStats');
T = S.Tcombined;

isTNFR1  = strcmp(string(T.RegionType),'TNFR1_cluster');
isRandom = strcmp(string(T.RegionType),'Random_control');
Ttnfr = T(isTNFR1,:);
Trand = T(isRandom,:);

fprintf('Loaded raw run: %d TNFR1 clusters, %d random-background points.\n', height(Ttnfr), height(Trand));

% Flatten Allstats/AllRandomStats (cell-of-struct-arrays) into simple struct
% arrays, one element per cluster, with sign-flip stats derived from the
% full CurvatureTimeSeries/ClassCodeTimeSeries.
Ctnfr = flattenClusterStats(S.Allstats,       classOrder);
Crand = flattenClusterStats(S.AllRandomStats, classOrder);
fprintf('Derived per-frame stats for %d TNFR1 clusters, %d random points.\n\n', numel(Ctnfr), numel(Crand));

TCtnfr = struct2table(rmfield(Ctnfr, {'Intervals','ClassCode'}));
TCrand = struct2table(rmfield(Crand, {'Intervals','ClassCode'}));

%% ================= GROUP A: SDt / Tension vs class & curvature fluctuation =================
fprintf('--- Group A: SDt/Tension correlations ---\n');

boxplotByClass(Ttnfr.Mean_FBR_SDt, string(Ttnfr.Classification), classOrder, ...
    'FBR SDt by classification (single-snapshot)', 'Mean FBR SDt', 'A1_SDt_by_class', outFolder);

boxplotByClass(Ttnfr.Mean_FBR_Tension, string(Ttnfr.Classification), classOrder, ...
    'FBR Tension by classification (single-snapshot)', 'Mean FBR Tension', 'A2_Tension_by_class', outFolder);

scatterWithCorr(Ttnfr.Mean_FBR_SDt, Ttnfr.SD_MeanCurvature_AllFrames, ...
    'Mean FBR SDt', 'SD of mean curvature (all frames)', 'SDt vs. curvature fluctuation', ...
    'A3_SDt_vs_SDcurvature', outFolder);

scatterWithCorr(Ttnfr.Mean_FBR_SDt, Ttnfr.FracClassChanges_AllFrames, ...
    'Mean FBR SDt', 'Fraction of frames with a class change', 'SDt vs. classification instability', ...
    'A4_SDt_vs_FracClassChanges', outFolder);

scatterWithCorr(Ttnfr.Mean_FBR_Tension, Ttnfr.SD_MeanCurvature_AllFrames, ...
    'Mean FBR Tension', 'SD of mean curvature (all frames)', 'Tension vs. curvature fluctuation', ...
    'A5_Tension_vs_SDcurvature', outFolder);

scatterWithCorr(Ttnfr.Mean_FBR_Tension, Ttnfr.FracClassChanges_AllFrames, ...
    'Mean FBR Tension', 'Fraction of frames with a class change', 'Tension vs. classification instability', ...
    'A6_Tension_vs_FracClassChanges', outFolder);

% NFlips comes from the flattened-struct dataset (TCtnfr), not the table
% (Ttnfr) -- pull SDt/Tension from TCtnfr too so rows stay correctly paired
% to the same cluster (Ttnfr and TCtnfr are not guaranteed to share row order).
scatterWithCorr(TCtnfr.SDt, TCtnfr.NFlips, ...
    'Mean FBR SDt', 'Number of curvature sign flips (2048 frames)', 'SDt vs. number of sign flips', ...
    'A7_SDt_vs_NFlips', outFolder);

scatterWithCorr(TCtnfr.Tension, TCtnfr.NFlips, ...
    'Mean FBR Tension', 'Number of curvature sign flips (2048 frames)', 'Tension vs. number of sign flips', ...
    'A8_Tension_vs_NFlips', outFolder);

predMat = [TCtnfr.SDt, TCtnfr.Tension, TCtnfr.SD_MeanCurvature, ...
           TCtnfr.FracClassChanges, TCtnfr.SD_ClassChanges, TCtnfr.NFlips];
predNames = {'SDt','Tension','SD MeanCurv','FracClassChg','SD ClassChg','NFlips'};
corrHeatmap(predMat, predNames, 'SDt/Tension vs. curvature & class fluctuation (Spearman)', ...
    'A9_correlation_heatmap_small', outFolder);

% SDt vs. (raw) curvature -- pooled across all clusters, and separately
% within each classification, so a class-specific relationship isn't
% washed out by (or mistaken for) the pooled trend.
stratifiedCorrHeatmap(Ttnfr.Mean_FBR_SDt, Ttnfr.MeanCurvature, string(Ttnfr.Classification), classOrder, ...
    'SDt vs. curvature -- pooled and by classification (Spearman)', 'A10_SDt_vs_curvature_by_class', outFolder);

%% ================= GROUP B: class % and curvature-by-class =================
fprintf('--- Group B: class percentages and curvature by class ---\n');

% B1/B2 — single-snapshot classification
[m,se,pooled,nG] = classPercentBySEM(string(Ttnfr.Classification), Ttnfr.CellID, classOrder);
[~,seSet,~,nGset] = classPercentBySEM(string(Ttnfr.Classification), Ttnfr.SetNum, classOrder);
barWithTwoSEM(m, se, seSet, classShort, pooled, ...
    sprintf('Class %% (single-snapshot) -- cells n=%d, sets n=%d', nG, nGset), 'B1_classpct_snapshot', outFolder);

boxplotByClass(Ttnfr.MeanCurvature, string(Ttnfr.Classification), classOrder, ...
    'Mean curvature by class (single-snapshot)', 'Mean curvature', 'B2_curvature_by_class_snapshot', outFolder);

% B2 above is TNFR1 only -- compare, within each class, whether TNFR1
% clusters and random background points have the same curvature magnitude,
% or whether a "SADDLE random point" looks different from a "SADDLE TNFR1
% cluster" even though both were assigned the same class.
boxplotByClassTwoGroups(Ttnfr.MeanCurvature, string(Ttnfr.Classification), ...
    Trand.MeanCurvature, string(Trand.Classification), classOrder, classShort, classColors, ...
    'Mean curvature by class: TNFR1 (blue) vs. random background (gray)', 'Mean curvature', ...
    'B7_curvature_by_class_vs_random', outFolder);

% B3/B4 — majority-vote classification (needs full time series -> TCtnfr)
[m,se,pooled,nG] = classPercentBySEM(string(TCtnfr.ClassMajority), TCtnfr.CellIdx, classOrder);
[~,seSet,~,nGset] = classPercentBySEM(string(TCtnfr.ClassMajority), TCtnfr.SetNum, classOrder);
barWithTwoSEM(m, se, seSet, classShort, pooled, ...
    sprintf('Class %% (majority-vote) -- cells n=%d, sets n=%d', nG, nGset), 'B3_classpct_majorityvote', outFolder);

boxplotByClass(TCtnfr.MeanCurvature, string(TCtnfr.ClassMajority), classOrder, ...
    'Mean curvature by class (majority-vote)', 'Mean curvature (per-cluster mean over 2048 frames)', ...
    'B4_curvature_by_class_majorityvote', outFolder);

% B5 — global-average classification (needs the averaged run's table).
% Skipped entirely if no avg64frames_fast run has been produced for this
% dataset yet (avgFolder left empty) -- everything else in this script only
% needs the raw run.
if ~isempty(avgFolder)
    cd(avgFolder);
    Savg = load('AllCells_CurvatureTopology_TimeSeries.mat','Tcombined');
    Tavg = Savg.Tcombined;
    isTNFR1avg = strcmp(string(Tavg.RegionType),'TNFR1_cluster');
    TavgTnfr = Tavg(isTNFR1avg,:);
    cd(rawFolder);

    [m,se,pooled,nG] = classPercentBySEM(string(TavgTnfr.GrandMeanFrame_Classification), TavgTnfr.CellID, classOrder);
    [~,seSet,~,nGset] = classPercentBySEM(string(TavgTnfr.GrandMeanFrame_Classification), TavgTnfr.SetNum, classOrder);
    barWithTwoSEM(m, se, seSet, classShort, pooled, ...
        sprintf('Class %% (global-average profile) -- cells n=%d, sets n=%d', nG, nGset), 'B5_classpct_globalavg', outFolder);

    boxplotByClass(TavgTnfr.GrandMeanFrame_MeanCurvature, string(TavgTnfr.GrandMeanFrame_Classification), classOrder, ...
        'Mean curvature by class (global-average profile)', 'Curvature of the averaged profile', ...
        'B6_curvature_by_class_globalavg', outFolder);
else
    fprintf('  (Skipping B5/B6 -- no avg64frames_fast run available for this dataset.)\n');
end

%% ================= GROUP C: TNFR1 clusters vs. random background =================
fprintf('--- Group C: cluster vs. random background ---\n');

boxplotTwoGroupsWhiskerScaled(Ttnfr.SD_MeanCurvature_AllFrames, Trand.SD_MeanCurvature_AllFrames, ...
    'TNFR1 cluster','Random background', 'SD of mean curvature: cluster vs. background', ...
    'SD of mean curvature (all frames)', 'C1_SDcurvature_cluster_vs_random', outFolder);

boxplotTwoGroupsWhiskerScaled(Ttnfr.FracClassChanges_AllFrames, Trand.FracClassChanges_AllFrames, ...
    'TNFR1 cluster','Random background', 'Classification instability: cluster vs. background', ...
    'Fraction of frames with a class change', 'C2_FracClassChanges_cluster_vs_random', outFolder);

boxplotTwoGroupsWhiskerScaled(TCtnfr.NFlips, TCrand.NFlips, ...
    'TNFR1 cluster','Random background', 'Number of curvature sign flips: cluster vs. background', ...
    'Sign flips over 2048 frames', 'C4_NFlips_cluster_vs_random', outFolder);

[grpPctTnfr, grpSEMTnfr, ~, ~, pctMatTnfr] = classPercentBySEM(string(Ttnfr.Classification), Ttnfr.CellID, classOrder);
[grpPctRand, grpSEMRand, ~, ~, pctMatRand] = classPercentBySEM(string(Trand.Classification), Trand.CellID, classOrder);

% Per-class significance: is this class over/under-represented in TNFR1
% clusters relative to random background, testing on per-cell percentages
% (Mann-Whitney, one test per class).
classPvals = nan(1, nClass);
for c = 1:nClass
    v1 = pctMatTnfr(:,c); v1 = v1(~isnan(v1));
    v2 = pctMatRand(:,c); v2 = v2(~isnan(v2));
    if numel(v1) >= 3 && numel(v2) >= 3
        classPvals(c) = ranksum(v1, v2);
    end
end
fprintf('  Class mix significance (Mann-Whitney on per-cell %%, TNFR1 vs. random):\n');
for c = 1:nClass
    fprintf('    %-12s p=%.3g %s\n', classShort{c}, classPvals(c), pToStars(classPvals(c)));
end

groupedBarTwoSeries(grpPctTnfr, grpSEMTnfr, grpPctRand, grpSEMRand, classShort, 'TNFR1 cluster','Random background', ...
    'Class mix: TNFR1 cluster vs. random background (mean % +/- SEM over cells)', '% of points', ...
    'C3_classmix_cluster_vs_random', outFolder, classPvals);

%% ================= GROUP D: sign-flip / time-between-flips / long-lived =================
fprintf('--- Group D: sign flips, time between flips, long-lived clusters ---\n');

fig = figure('Color','w','Position',[100 100 700 450]);
hold on;
histogram(TCtnfr.NFlips, 'BinWidth',20, 'FaceColor',classColors(1,:), 'FaceAlpha',0.55, 'Normalization','probability');
histogram(TCrand.NFlips, 'BinWidth',20, 'FaceColor',[0.5 0.5 0.5], 'FaceAlpha',0.55, 'Normalization','probability');
xlabel('Number of curvature sign flips (2048 frames)'); ylabel('Fraction of clusters');
legend({'TNFR1 cluster','Random background'}); title('Distribution of sign-flip counts');
saveFigure(fig, 'D1_NFlips_histogram', outFolder);

% pool RAW inter-flip intervals (not per-cluster means) tagged by class
[allIv, allIvClass] = pooledIntervalsByClass(Ctnfr);
boxplotByClass(allIv, allIvClass, classOrder, ...
    'Time between curvature sign flips, by class (pooled intervals)', 'Frames between consecutive sign flips', ...
    'D2_intervals_by_class', outFolder);

boxplotByClass(TCtnfr.NFlips, string(TCtnfr.ClassSnapshot), classOrder, ...
    'Number of sign flips by class', 'Sign flips over 2048 frames', 'D3_NFlips_by_class', outFolder);

% long-lived = Tukey upper-fence outlier on mean inter-flip interval
% (clusters with <2 flips in 2048 frames are long-lived by definition)
mi = TCtnfr.MeanInterval;
validMI = ~isnan(mi);
q = quantile(mi(validMI), [0.25 0.75]);
fenceHi = q(2) + 1.5*diff(q);
LongLived = false(height(TCtnfr),1);
LongLived(validMI)  = mi(validMI) > fenceHi;
LongLived(~validMI) = true;
fprintf('Long-lived fence (mean inter-flip interval) = %.1f frames -> %d/%d clusters flagged long-lived.\n', ...
    fenceHi, sum(LongLived), numel(LongLived));

llCounts = countByClass(string(TCtnfr.ClassSnapshot(LongLived)), classOrder);
llErr = sqrt(llCounts); % Poisson approximation for the uncertainty on a raw count
fig = figure('Color','w','Position',[100 100 650 420]); hold on;
bar(llCounts, 'FaceColor', classColors(1,:));
errorbar(1:nClass, llCounts, llErr, 'k.', 'LineWidth',1.2, 'CapSize',6, 'LineStyle','none');
set(gca,'XTick',1:nClass,'XTickLabel',classShort);
ylabel('Number of long-lived clusters'); title('Long-lived (rarely-flipping) clusters, by class');
saveFigure(fig, 'D4_longlived_counts_by_class', outFolder);

% index with TCtnfr's own SDt/Tension (not Ttnfr) -- LongLived was computed
% in TCtnfr row order, and TCtnfr/Ttnfr are not guaranteed to share row order.
boxplotTwoGroupsWhiskerScaled(TCtnfr.SDt(LongLived), TCtnfr.SDt(~LongLived), ...
    'Long-lived','Rest', 'FBR SDt: long-lived vs. rest', 'Mean FBR SDt', 'D5_SDt_longlived_vs_rest', outFolder);

boxplotTwoGroupsWhiskerScaled(TCtnfr.Tension(LongLived), TCtnfr.Tension(~LongLived), ...
    'Long-lived','Rest', 'FBR Tension: long-lived vs. rest', 'Mean FBR Tension', 'D6_Tension_longlived_vs_rest', outFolder);

% Same long-lived (Tukey upper-fence on mean inter-flip interval) definition,
% computed independently within random background points -- checking whether
% "long-lived = low tension" is a TNFR1-specific effect or holds for random
% background too.
miR = TCrand.MeanInterval;
validMiR = ~isnan(miR);
qR = quantile(miR(validMiR), [0.25 0.75]);
fenceHiR = qR(2) + 1.5*diff(qR);
LongLivedRand = false(height(TCrand),1);
LongLivedRand(validMiR)  = miR(validMiR) > fenceHiR;
LongLivedRand(~validMiR) = true;
fprintf('Long-lived fence (random background) = %.1f frames -> %d/%d random points flagged long-lived.\n', ...
    fenceHiR, sum(LongLivedRand), numel(LongLivedRand));

boxplotTwoGroupsWhiskerScaled(TCrand.SDt(LongLivedRand), TCrand.SDt(~LongLivedRand), ...
    'Long-lived','Rest', 'FBR SDt: long-lived vs. rest (RANDOM background)', 'Mean FBR SDt', ...
    'D7_SDt_longlived_vs_rest_random', outFolder);

boxplotTwoGroupsWhiskerScaled(TCrand.Tension(LongLivedRand), TCrand.Tension(~LongLivedRand), ...
    'Long-lived','Rest', 'FBR Tension: long-lived vs. rest (RANDOM background)', 'Mean FBR Tension', ...
    'D8_Tension_longlived_vs_rest_random', outFolder);

% Does the CLASS MIX of long-lived clusters differ from the overall TNFR1
% class mix, and from long-lived random points' class mix? (All computed
% from TCtnfr/TCrand's own ClassSnapshot so the three groups share exactly
% one classification source each -- no cross-table row-alignment risk.)
countsLL_Tnfr  = countByClass(string(TCtnfr.ClassSnapshot(LongLived)), classOrder);
countsAll_Tnfr = countByClass(string(TCtnfr.ClassSnapshot), classOrder);
countsLL_Rand  = countByClass(string(TCrand.ClassSnapshot(LongLivedRand)), classOrder);

pctLL_Tnfr  = 100 * countsLL_Tnfr  / sum(countsLL_Tnfr);
pctAll_Tnfr = 100 * countsAll_Tnfr / sum(countsAll_Tnfr);
pctLL_Rand  = 100 * countsLL_Rand  / sum(countsLL_Rand);

pChi_LLvsAll  = chiSquareTest(countsLL_Tnfr, countsAll_Tnfr);
pChi_LLvsRand = chiSquareTest(countsLL_Tnfr, countsLL_Rand);
fprintf('  Long-lived TNFR1 class mix (n=%d) vs. overall TNFR1 class mix (n=%d): chi-square p=%.3g\n', ...
    sum(countsLL_Tnfr), sum(countsAll_Tnfr), pChi_LLvsAll);
fprintf('  Long-lived TNFR1 class mix (n=%d) vs. long-lived random class mix (n=%d): chi-square p=%.3g\n', ...
    sum(countsLL_Tnfr), sum(countsLL_Rand), pChi_LLvsRand);

plotGrouped3Series(pctLL_Tnfr, sum(countsLL_Tnfr), pctAll_Tnfr, sum(countsAll_Tnfr), ...
    pctLL_Rand, sum(countsLL_Rand), classShort, ...
    'Long-lived TNFR1', 'All TNFR1 (overall)', 'Long-lived random', ...
    sprintf('Class mix: long-lived vs. overall vs. long-lived random (chi2 LL-vs-all p=%.2g, LL-vs-LLrandom p=%.2g)', ...
        pChi_LLvsAll, pChi_LLvsRand), ...
    '% within group', 'D9_longlived_classmix_comparison', outFolder);

%% ================= GROUP E: predictor sweep, transition network, class-range =================
fprintf('--- Group E: full predictor sweep, transition network, class-range ---\n');

bigMat = [Ttnfr.Area, Ttnfr.Circularity, Ttnfr.Eccentricity, Ttnfr.EquivDiameter, Ttnfr.Solidity, ...
          Ttnfr.MajorAxisLength, Ttnfr.MinorAxisLength, Ttnfr.Perimeter, ...
          Ttnfr.MeanIntensity, Ttnfr.TotalIntensity, ...
          Ttnfr.Mean_FBR_SDt, Ttnfr.Mean_FBR_Tension, Ttnfr.MeanCurvature, ...
          Ttnfr.SD_MeanCurvature_AllFrames, Ttnfr.FracClassChanges_AllFrames];
bigNames = {'Area','Circularity','Eccentricity','EquivDiam','Solidity','MajorAxis','MinorAxis', ...
            'Perimeter','MeanIntensity','TotalIntensity','SDt','Tension','Curvature','SD MeanCurv','FracClassChg'};
corrHeatmap(bigMat, bigNames, 'Full predictor correlation sweep (Spearman)', 'E1_full_predictor_heatmap', outFolder);

codeCellArray = {Ctnfr.ClassCode};
transitionNetwork(codeCellArray, classOrder, classShort, 'TNFR1 cluster class transitions', ...
    'E2_transition_heatmap', 'E2_transition_network', outFolder);

classRange = cellfun(@(c) numel(unique(c(~isnan(c)))), {Ctnfr.ClassCode})';
boxplotByClass(classRange, string(TCtnfr.ClassSnapshot), classOrder, ...
    'Class-range (# distinct classes visited) by snapshot class', '# distinct classes visited over 2048 frames', ...
    'E3_classrange_by_class', outFolder);

fig = figure('Color','w','Position',[100 100 650 420]);
histogram(classRange, 'BinMethod','integers', 'FaceColor', classColors(3,:));
xlabel('# distinct classes visited (out of 5)'); ylabel('# clusters');
title('How many classes does a cluster wander through over 2048 frames?');
saveFigure(fig, 'E4_classrange_histogram', outFolder);

% Why can a cluster visit all 5 classes if the transition network (E2) shows
% mostly ADJACENT-only bounces (e.g. SADDLE<->RIDGE), never big jumps? Answer:
% it doesn't need big jumps -- with ~170 flips on average over 2048 frames
% (mean inter-flip interval ~12 frames), repeated local bounces are enough to
% eventually drift across the whole 5-class range, the same way a 1D random
% walk restricted to +/-1 steps still visits every position given enough
% steps. This checks that directly: more flips -> more classes visited.
scatterWithCorr(TCtnfr.NFlips, classRange, 'Number of sign flips (2048 frames)', ...
    '# distinct classes visited', 'Sign-flip count vs. class-range -- more local bounces reach more classes', ...
    'E5_NFlips_vs_classrange', outFolder);

for cr = [1 5]
    mask = classRange == cr;
    if any(mask)
        fprintf('  Clusters visiting %d class(es): n=%d, median NFlips=%.0f\n', ...
            cr, sum(mask), median(TCtnfr.NFlips(mask), 'omitnan'));
    end
end

%% ================= GROUP F: transition PATTERN probabilities (e.g. PIT -> SADDLE -> DOME/HILL) =================
% Raw frame-to-frame transitions (Group E's heatmap) are dominated by
% self-transitions, since a cluster dwells ~12 frames in a class before
% flipping (Group D). A "pattern" like pit->saddle->dome is a question about
% the sequence of ACTUAL class changes, so we first collapse each cluster's
% 2048-frame code series down to only the classes it changes into (run-length
% compression), then compute 2-step and 3-step pattern probabilities on that.
fprintf('--- Group F: transition pattern probabilities (compressed change-sequences) ---\n');

seqs = cellfun(@runLengthCompress, {Ctnfr.ClassCode}, 'UniformOutput', false);
nSeqWithChanges = sum(cellfun(@numel, seqs) >= 2);
fprintf('  %d / %d TNFR1 clusters have at least one class change to draw patterns from.\n', nSeqWithChanges, numel(seqs));

% F1: single-step pattern probability -- P(next actual class | current class),
% self-transitions impossible by construction (already compressed).
Mprob = bigramProbMatrix(seqs, nClass);
fig = figure('Color','w','Position',[100 100 640 560]);
imagesc(Mprob); axis square; colormap(parula); colorbar; caxis([0 1]);
set(gca,'XTick',1:nClass,'XTickLabel',classShort,'YTick',1:nClass,'YTickLabel',classShort);
for i = 1:nClass
    for j = 1:nClass
        txtColor = 'k';
        if Mprob(i,j) > 0.55; txtColor = 'w'; end
        text(j, i, sprintf('%.2f', Mprob(i,j)), 'HorizontalAlignment','center', 'FontSize',9, 'Color', txtColor);
    end
end
xlabel('to class (next actual change)'); ylabel('from class (just arrived from)');
title('1-step pattern probability -- P(next class | current class), dwell time ignored', 'Interpreter','none');
saveFigure(fig, 'F1_pattern_1step_probability', outFolder);

% F2/F3: 3-step patterns (e.g. PIT -> SADDLE -> DOME/HILL)
[triCombo, triCount, triMargProb, triCondProb] = trigramStats(seqs, classOrder);
[triCount, order] = sort(triCount, 'descend');
triCombo = triCombo(order,:); triMargProb = triMargProb(order); triCondProb = triCondProb(order);

Ttri = table(triCombo(:,1), triCombo(:,2), triCombo(:,3), triCount, 100*triMargProb, 100*triCondProb, ...
    'VariableNames', {'From','Via','To','Count','ProbAmongAll3StepPatterns_pct','ProbGivenFirstTwoSteps_pct'});
writetable(Ttri, fullfile(outFolder, 'F3_transition_patterns_3step.csv'));

nTop = min(15, height(Ttri));
plotCount = triCount(nTop:-1:1);
plotCombo = triCombo(nTop:-1:1,:);
lbls = strcat(plotCombo(:,1), " -> ", plotCombo(:,2), " -> ", plotCombo(:,3));
fig = figure('Color','w','Position',[150 100 920 540]);
barh(plotCount, 'FaceColor', classColors(1,:));
set(gca,'YTick',1:nTop,'YTickLabel',lbls,'TickLabelInterpreter','none');
xlabel('# occurrences (pooled across 200 TNFR1 clusters)');
title('Most common 3-step class-change patterns', 'Interpreter','none');
for i = 1:nTop
    text(plotCount(i) + max(triCount)*0.01, i, sprintf('%.1f%%', 100*plotCount(i)/sum(triCount)), ...
        'VerticalAlignment','middle', 'FontSize',8);
end
saveFigure(fig, 'F2_top_patterns_3step', outFolder);

fprintf('  Total 3-step patterns observed: %d (pooled across %d clusters)\n', sum(triCount), nSeqWithChanges);
fprintf('  Most common pattern: %s -> %s -> %s  (n=%d, %.1f%% of all 3-step patterns)\n', ...
    triCombo(1,1), triCombo(1,2), triCombo(1,3), triCount(1), 100*triMargProb(1));
fprintf('  Full ranked table (all patterns, both probability definitions) saved to F3_transition_patterns_3step.csv\n');

% Look up the user's example pattern specifically, wherever it ranks.
exampleFrom = "CUP / PIT"; exampleVia = "SADDLE"; exampleTo = "DOME / HILL";
exMask = triCombo(:,1)==exampleFrom & triCombo(:,2)==exampleVia & triCombo(:,3)==exampleTo;
if any(exMask)
    fprintf('  Example "%s -> %s -> %s": n=%d, %.1f%% of all 3-step patterns, %.1f%% conditional on reaching %s via %s (rank %d of %d)\n', ...
        exampleFrom, exampleVia, exampleTo, triCount(exMask), 100*triMargProb(exMask), ...
        100*triCondProb(exMask), exampleVia, exampleFrom, find(exMask), numel(triCount));
else
    fprintf('  Example "%s -> %s -> %s" was never observed in this dataset.\n', exampleFrom, exampleVia, exampleTo);
end

%% ================= GROUP G: transition-into-class, TNFR1 vs. random background =================
% For each cluster, what fraction of its actual class changes land ON each
% class (e.g. "of all the times this cluster's class changed, how often did
% it end up SADDLE")? Compared class-by-class against the random-background
% control via boxplot + Mann-Whitney, to see whether TNFR1 clusters favor
% transitioning into particular classes more than randomly-walking background
% points do.
fprintf('--- Group G: transition-into-class, TNFR1 vs. random background ---\n');

seqsRand = cellfun(@runLengthCompress, {Crand.ClassCode}, 'UniformOutput', false);

plotTransitionIntoClassVsRandom(seqs, seqsRand, nClass, classShort, classColors, ...
    'Transition-into-class fraction: TNFR1 clusters (blue) vs. random background (gray)', ...
    'G1_transition_into_class_vs_random', outFolder);

% G1 above only compares the MARGINAL "which class did it land on" fraction.
% G2 checks each of the 20 specific ordered transitions (e.g. PIT->SADDLE,
% specifically, not just "landed on SADDLE") against random individually.
plotTransitionPairsVsRandom(seqs, seqsRand, nClass, classShort, classColors, ...
    'Each specific transition pair: TNFR1 (blue) vs. random background (gray)', ...
    'G2_transition_pairs_vs_random', outFolder);

%% ================= GROUP H/I: same transition-pattern analysis on CLUBBED (64-frame-block) data =================
% Groups F and G above use the full 2048-frame time series, which is noisy
% frame-to-frame. This repeats both on the Avg64Frames_Fast run, where each
% cluster's class-code series is only 32 points long (one classification per
% averaged 64-frame block) -- a denoised, coarser-time-resolution version of
% the same patterns.
if isempty(avgFolder)
    fprintf('--- Group H/I/J: skipped -- no avg64frames_fast run available for this dataset. ---\n');
else
fprintf('--- Group H/I: transition patterns on clubbed (64-frame-block) data ---\n');

cd(avgFolder);
Savg = load('AllCells_CurvatureTopology_TimeSeries.mat', 'Allstats', 'AllRandomStats');
CtnfrBlk = flattenClusterStats(Savg.Allstats,       classOrder);
CrandBlk = flattenClusterStats(Savg.AllRandomStats, classOrder);
cd(rawFolder);
nBlocksPerCluster = numel(CtnfrBlk(1).ClassCode);
framesPerBlock = round(2048 / max(1, nBlocksPerCluster));
fprintf('  Loaded clubbed run: %d TNFR1 clusters, %d random points, %d blocks/cluster (~%d frames/block).\n', ...
    numel(CtnfrBlk), numel(CrandBlk), nBlocksPerCluster, framesPerBlock);

seqsBlk     = cellfun(@runLengthCompress, {CtnfrBlk.ClassCode}, 'UniformOutput', false);
seqsRandBlk = cellfun(@runLengthCompress, {CrandBlk.ClassCode}, 'UniformOutput', false);
nSeqBlkWithChanges = sum(cellfun(@numel, seqsBlk) >= 2);
fprintf('  %d / %d TNFR1 clusters have at least one class change across the 32 blocks.\n', nSeqBlkWithChanges, numel(seqsBlk));

% H1: 1-step pattern probability, clubbed data
MprobBlk = bigramProbMatrix(seqsBlk, nClass);
fig = figure('Color','w','Position',[100 100 640 560]);
imagesc(MprobBlk); axis square; colormap(parula); colorbar; caxis([0 1]);
set(gca,'XTick',1:nClass,'XTickLabel',classShort,'YTick',1:nClass,'YTickLabel',classShort);
for i = 1:nClass
    for j = 1:nClass
        txtColor = 'k';
        if MprobBlk(i,j) > 0.55; txtColor = 'w'; end
        text(j, i, sprintf('%.2f', MprobBlk(i,j)), 'HorizontalAlignment','center', 'FontSize',9, 'Color', txtColor);
    end
end
xlabel('to class (next actual change)'); ylabel('from class (just arrived from)');
title('1-step pattern probability -- CLUBBED data (32 x 64-frame blocks)', 'Interpreter','none');
saveFigure(fig, 'H1_pattern_1step_probability_clubbed', outFolder);

% H2/H3: 3-step patterns, clubbed data
[triComboBlk, triCountBlk, triMargProbBlk, triCondProbBlk] = trigramStats(seqsBlk, classOrder);
[triCountBlk, orderBlk] = sort(triCountBlk, 'descend');
triComboBlk = triComboBlk(orderBlk,:); triMargProbBlk = triMargProbBlk(orderBlk); triCondProbBlk = triCondProbBlk(orderBlk);

TtriBlk = table(triComboBlk(:,1), triComboBlk(:,2), triComboBlk(:,3), triCountBlk, ...
    100*triMargProbBlk, 100*triCondProbBlk, ...
    'VariableNames', {'From','Via','To','Count','ProbAmongAll3StepPatterns_pct','ProbGivenFirstTwoSteps_pct'});
writetable(TtriBlk, fullfile(outFolder, 'H3_transition_patterns_3step_clubbed.csv'));

nTopBlk = min(15, height(TtriBlk));
if nTopBlk > 0
    plotCountBlk = triCountBlk(nTopBlk:-1:1);
    plotComboBlk = triComboBlk(nTopBlk:-1:1,:);
    lblsBlk = strcat(plotComboBlk(:,1), " -> ", plotComboBlk(:,2), " -> ", plotComboBlk(:,3));
    fig = figure('Color','w','Position',[150 100 920 540]);
    barh(plotCountBlk, 'FaceColor', classColors(1,:));
    set(gca,'YTick',1:nTopBlk,'YTickLabel',lblsBlk,'TickLabelInterpreter','none');
    xlabel('# occurrences (pooled across 200 TNFR1 clusters, 32 blocks each)');
    title('Most common 3-step class-change patterns -- CLUBBED data', 'Interpreter','none');
    for i = 1:nTopBlk
        text(plotCountBlk(i) + max(triCountBlk)*0.01, i, sprintf('%.1f%%', 100*plotCountBlk(i)/sum(triCountBlk)), ...
            'VerticalAlignment','middle', 'FontSize',8);
    end
    saveFigure(fig, 'H2_top_patterns_3step_clubbed', outFolder);
    fprintf('  Most common pattern (clubbed): %s -> %s -> %s  (n=%d, %.1f%% of all 3-step patterns)\n', ...
        triComboBlk(1,1), triComboBlk(1,2), triComboBlk(1,3), triCountBlk(1), 100*triMargProbBlk(1));
else
    fprintf('  No 3-step patterns found in the clubbed data (too few blocks per cluster change class).\n');
end

% I1: transition-into-class, TNFR1 vs random, clubbed data
plotTransitionIntoClassVsRandom(seqsBlk, seqsRandBlk, nClass, classShort, classColors, ...
    'Transition-into-class fraction (CLUBBED data): TNFR1 (blue) vs. random background (gray)', ...
    'I1_transition_into_class_vs_random_clubbed', outFolder);

% I2: each specific transition pair, TNFR1 vs random, clubbed data
plotTransitionPairsVsRandom(seqsBlk, seqsRandBlk, nClass, classShort, classColors, ...
    'Each specific transition pair (CLUBBED data): TNFR1 (blue) vs. random background (gray)', ...
    'I2_transition_pairs_vs_random_clubbed', outFolder);

%% ================= GROUP J: SDt/Tension vs. sign-flip frequency, TNFR1 vs. random =================
% A7/A8 showed SDt/Tension vs. sign-flip frequency for TNFR1 only, because
% random points didn't carry real FBR SDt/Tension in the run those used.
% Random points in the clubbed run now do (CrandBlk, via the same
% addFBR_values_to_objects lookup as real clusters), so check directly
% whether the same dependence holds for random background or is specific to
% real TNFR1 clusters.
fprintf('--- Group J: SDt/Tension vs. sign-flip frequency, TNFR1 vs. random (clubbed data) ---\n');

scatterWithCorrTwoGroups([CtnfrBlk.SDt], [CtnfrBlk.NFlips], [CrandBlk.SDt], [CrandBlk.NFlips], ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'Number of sign flips (32 blocks)', ...
    'SDt vs. sign-flip frequency: TNFR1 vs. random background', 'J1_SDt_vs_NFlips_vs_random_clubbed', outFolder);

scatterWithCorrTwoGroups([CtnfrBlk.Tension], [CtnfrBlk.NFlips], [CrandBlk.Tension], [CrandBlk.NFlips], ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'Number of sign flips (32 blocks)', ...
    'Tension vs. sign-flip frequency: TNFR1 vs. random background', 'J2_Tension_vs_NFlips_vs_random_clubbed', outFolder);

% TNFR1 clusters show a significant SDt/Tension vs. SD-of-class-change
% correlation (see A9's heatmap); check whether random background shows the
% same dependence or whether it's specific to real clusters.
scatterWithCorrTwoGroups([CtnfrBlk.SDt], [CtnfrBlk.SD_ClassChanges], [CrandBlk.SDt], [CrandBlk.SD_ClassChanges], ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'SD of classification changes (32 blocks)', ...
    'SDt vs. SD of class-change frequency: TNFR1 vs. random background', 'J3_SDt_vs_SDClassChanges_vs_random_clubbed', outFolder);

scatterWithCorrTwoGroups([CtnfrBlk.Tension], [CtnfrBlk.SD_ClassChanges], [CrandBlk.Tension], [CrandBlk.SD_ClassChanges], ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'SD of classification changes (32 blocks)', ...
    'Tension vs. SD of class-change frequency: TNFR1 vs. random background', 'J4_Tension_vs_SDClassChanges_vs_random_clubbed', outFolder);

% A4/A6 showed SDt/Tension vs. fraction-of-frames-with-a-class-change for
% TNFR1 only (significant on the raw run); check random background too.
scatterWithCorrTwoGroups([CtnfrBlk.SDt], [CtnfrBlk.FracClassChanges], [CrandBlk.SDt], [CrandBlk.FracClassChanges], ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'Fraction of blocks with a class change (32 blocks)', ...
    'SDt vs. fraction of class changes: TNFR1 vs. random background', 'J5_SDt_vs_FracClassChanges_vs_random_clubbed', outFolder);

scatterWithCorrTwoGroups([CtnfrBlk.Tension], [CtnfrBlk.FracClassChanges], [CrandBlk.Tension], [CrandBlk.FracClassChanges], ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'Fraction of blocks with a class change (32 blocks)', ...
    'Tension vs. fraction of class changes: TNFR1 vs. random background', 'J6_Tension_vs_FracClassChanges_vs_random_clubbed', outFolder);
end % isempty(avgFolder)

%% ================= GROUP K: percentage of positive vs. negative mean curvature =================
fprintf('--- Group K: percentage of positive vs. negative mean curvature ---\n');

signOrder = {'Positive','Negative'};
signLabelTnfr = repmat("Positive", height(Ttnfr), 1);
signLabelTnfr(Ttnfr.MeanCurvature < 0) = "Negative";
signLabelRand = repmat("Positive", height(Trand), 1);
signLabelRand(Trand.MeanCurvature < 0) = "Negative";

[pctSignTnfr, semSignTnfr, pooledSignTnfr, ~, pctMatSignTnfr] = classPercentBySEM(signLabelTnfr, Ttnfr.CellID, signOrder);
[pctSignRand, semSignRand, pooledSignRand, ~, pctMatSignRand] = classPercentBySEM(signLabelRand, Trand.CellID, signOrder);

signPvals = nan(1, numel(signOrder));
for c = 1:numel(signOrder)
    v1 = pctMatSignTnfr(:,c); v1 = v1(~isnan(v1));
    v2 = pctMatSignRand(:,c); v2 = v2(~isnan(v2));
    if numel(v1) >= 3 && numel(v2) >= 3
        signPvals(c) = ranksum(v1, v2);
    end
end

groupedBarTwoSeries(pctSignTnfr, semSignTnfr, pctSignRand, semSignRand, signOrder, ...
    'TNFR1 cluster','Random background', ...
    'Percentage of clusters with positive vs. negative mean curvature (mean % +/- SEM over cells)', ...
    '% of points', 'K1_curvature_sign_percentage', outFolder, signPvals);

fprintf('  TNFR1:  Positive=%.1f%%(pooled %.1f%%)  Negative=%.1f%%(pooled %.1f%%)\n', ...
    pctSignTnfr(1), pooledSignTnfr(1), pctSignTnfr(2), pooledSignTnfr(2));
fprintf('  Random: Positive=%.1f%%(pooled %.1f%%)  Negative=%.1f%%(pooled %.1f%%)\n', ...
    pctSignRand(1), pooledSignRand(1), pctSignRand(2), pooledSignRand(2));
fprintf('  Mann-Whitney (per-cell %%, TNFR1 vs. random): Positive p=%.3g %s   Negative p=%.3g %s\n', ...
    signPvals(1), pToStars(signPvals(1)), signPvals(2), pToStars(signPvals(2)));

%% ================= GROUP L: SDt/Tension correlations, TNFR1 vs. random, FULL 2048-frame data =================
% Group J did this on the clubbed (32-block) data because that was the only
% run where random points had real FBR SDt/Tension -- but the clubbed data
% washes out these relationships even for TNFR1 (they're significant on the
% raw run, not on the clubbed one), so J wasn't actually a fair test of the
% original question. Now that the RAW run also has real random-point
% SDt/Tension (Trand/TCrand, no longer NaN), repeat A3-A8 here as direct
% TNFR1-vs-random overlays at full time resolution -- the real answer.
fprintf('--- Group L: SDt/Tension vs. curvature/class-change metrics, TNFR1 vs. random (FULL 2048-frame data) ---\n');

nRandSDt = sum(~isnan(TCrand.SDt));
fprintf('  Random points with real FBR SDt in this run: %d / %d\n', nRandSDt, height(TCrand));

scatterWithCorrTwoGroups(TCtnfr.SDt, TCtnfr.SD_MeanCurvature, TCrand.SDt, TCrand.SD_MeanCurvature, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'SD of mean curvature (2048 frames)', ...
    'SDt vs. SD of mean curvature: TNFR1 vs. random background (full data)', 'L1_SDt_vs_SDcurvature_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.Tension, TCtnfr.SD_MeanCurvature, TCrand.Tension, TCrand.SD_MeanCurvature, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'SD of mean curvature (2048 frames)', ...
    'Tension vs. SD of mean curvature: TNFR1 vs. random background (full data)', 'L2_Tension_vs_SDcurvature_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.SDt, TCtnfr.FracClassChanges, TCrand.SDt, TCrand.FracClassChanges, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'Fraction of frames with a class change (2048 frames)', ...
    'SDt vs. fraction of class changes: TNFR1 vs. random background (full data)', 'L3_SDt_vs_FracClassChanges_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.Tension, TCtnfr.FracClassChanges, TCrand.Tension, TCrand.FracClassChanges, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'Fraction of frames with a class change (2048 frames)', ...
    'Tension vs. fraction of class changes: TNFR1 vs. random background (full data)', 'L4_Tension_vs_FracClassChanges_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.SDt, TCtnfr.NFlips, TCrand.SDt, TCrand.NFlips, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'Number of sign flips (2048 frames)', ...
    'SDt vs. sign-flip frequency: TNFR1 vs. random background (full data)', 'L5_SDt_vs_NFlips_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.Tension, TCtnfr.NFlips, TCrand.Tension, TCrand.NFlips, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'Number of sign flips (2048 frames)', ...
    'Tension vs. sign-flip frequency: TNFR1 vs. random background (full data)', 'L6_Tension_vs_NFlips_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.SDt, TCtnfr.SD_ClassChanges, TCrand.SDt, TCrand.SD_ClassChanges, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR SDt', 'SD of classification changes (2048 frames)', ...
    'SDt vs. SD of class-change frequency: TNFR1 vs. random background (full data)', 'L7_SDt_vs_SDClassChanges_vs_random', outFolder);

scatterWithCorrTwoGroups(TCtnfr.Tension, TCtnfr.SD_ClassChanges, TCrand.Tension, TCrand.SD_ClassChanges, ...
    'TNFR1 cluster', 'Random background', 'Mean FBR Tension', 'SD of classification changes (2048 frames)', ...
    'Tension vs. SD of class-change frequency: TNFR1 vs. random background (full data)', 'L8_Tension_vs_SDClassChanges_vs_random', outFolder);

fprintf('\nAll done. %d figures saved to:\n  %s\n', numel(dir(fullfile(outFolder,'*.png'))), outFolder);


%% ================= LOCAL HELPER FUNCTIONS =================
function val = getFieldOrNaN(s, fieldName)
    if isfield(s, fieldName) && ~isempty(s.(fieldName))
        val = double(s.(fieldName));
    else
        val = NaN;
    end
end

function lbl = codeToLabel(code, classOrder)
    code = round(code);
    if isnan(code) || code < 1 || code > numel(classOrder)
        lbl = "UNKNOWN";
    else
        lbl = string(classOrder{code});
    end
end

function C = flattenClusterStats(statsCell, classOrder)
    C = struct('CellIdx',{}, 'SetNum',{}, 'PlateNum',{}, 'ClassSnapshot',{}, 'ClassMajority',{}, ...
        'MeanCurvature',{}, 'SD_MeanCurvature',{}, 'NumClassChanges',{}, 'FracClassChanges',{}, ...
        'SD_ClassChanges',{}, 'SDt',{}, 'Tension',{}, 'NFlips',{}, 'MeanInterval',{}, ...
        'Intervals',{}, 'ClassCode',{});
    idx = 0;
    for cellIdx = 1:numel(statsCell)
        entry = statsCell{cellIdx};
        while iscell(entry) && numel(entry) == 1   % unwrap extra cell nesting, if any
            entry = entry{1};
        end
        if isempty(entry) || ~isstruct(entry); continue; end   % e.g. a cell with 0 clusters
        for k = 1:numel(entry)
            s = entry(k);
            curv = double(s.CurvatureTimeSeries(:));
            code = double(s.ClassCodeTimeSeries(:));
            if isempty(curv) || isempty(code); continue; end

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
            flipIdx = find(diff(signVec) ~= 0);
            nFlips = numel(flipIdx);
            if nFlips >= 2
                intervals = diff(flipIdx);
                meanInterval = mean(intervals);
            else
                intervals = [];
                meanInterval = NaN;
            end

            idx = idx + 1;
            C(idx).CellIdx          = cellIdx;
            C(idx).SetNum           = double(s.SetNum);
            C(idx).PlateNum         = double(s.PlateNum);
            C(idx).ClassSnapshot    = codeToLabel(code(1), classOrder);
            C(idx).ClassMajority    = codeToLabel(mode(code), classOrder);
            C(idx).MeanCurvature    = mean(curv);
            C(idx).SD_MeanCurvature = getFieldOrNaN(s, 'SD_MeanCurvature_AllFrames');
            C(idx).NumClassChanges  = getFieldOrNaN(s, 'NumClassChanges_AllFrames');
            C(idx).FracClassChanges = getFieldOrNaN(s, 'FracClassChanges_AllFrames');
            C(idx).SD_ClassChanges  = getFieldOrNaN(s, 'SD_ClassChanges_AllFrames');
            C(idx).SDt              = getFieldOrNaN(s, 'Mean_FBR_SDt');
            C(idx).Tension          = getFieldOrNaN(s, 'Mean_FBR_Tension');
            C(idx).NFlips           = nFlips;
            C(idx).MeanInterval     = meanInterval;
            C(idx).Intervals        = intervals;
            C(idx).ClassCode        = code;
        end
    end
end

function seq = runLengthCompress(code)
    % Collapse a per-frame class-code series down to the sequence of
    % actual class CHANGES (consecutive repeats removed), e.g.
    % [3 3 3 3 1 1 5 5 5] -> [3 1 5]. NaNs (unclassified frames) dropped first.
    code = round(code(:));
    code = code(~isnan(code));
    if isempty(code)
        seq = [];
        return;
    end
    keep = [true; diff(code) ~= 0];
    seq = code(keep);
end

function Mprob = bigramProbMatrix(seqs, nClass)
    % P(next class | current class) over consecutive entries of the
    % already-compressed change-sequences (self-transitions impossible).
    M = zeros(nClass, nClass);
    for i = 1:numel(seqs)
        s = seqs{i};
        if numel(s) < 2; continue; end
        c1 = s(1:end-1); c2 = s(2:end);
        valid = c1 >= 1 & c1 <= nClass & c2 >= 1 & c2 <= nClass;
        c1 = c1(valid); c2 = c2(valid);
        idx = sub2ind([nClass nClass], c1, c2);
        counts = accumarray(idx(:), 1, [nClass*nClass, 1]);
        M = M + reshape(counts, [nClass, nClass]);
    end
    rowSum = sum(M,2);
    rowSum(rowSum==0) = 1;
    Mprob = M ./ rowSum;
end

function [combo, cnt, margProb, condProb] = trigramStats(seqs, classOrder)
    % Counts every 3-in-a-row window (From, Via, To) across all compressed
    % change-sequences, plus two probability views:
    %   margProb = P(this exact 3-step pattern) among ALL 3-step patterns seen
    %   condProb = P(To | From, Via) -- given you're at From and step to Via,
    %              how likely is the next step To
    nClass = numel(classOrder);
    counts3 = zeros(nClass, nClass, nClass);
    for i = 1:numel(seqs)
        s = seqs{i};
        if numel(s) < 3; continue; end
        for t = 1:(numel(s)-2)
            a = s(t); b = s(t+1); c = s(t+2);
            if a>=1 && a<=nClass && b>=1 && b<=nClass && c>=1 && c<=nClass
                counts3(a,b,c) = counts3(a,b,c) + 1;
            end
        end
    end
    total = sum(counts3(:));
    [ai, bi, ci] = ind2sub(size(counts3), find(counts3 > 0));
    cnt = counts3(sub2ind(size(counts3), ai, bi, ci));
    combo = strings(numel(ai), 3);   % explicit loop -- indexing a row-cell with a
    for k = 1:numel(ai)              % column index returns a row (matches classOrder's
        combo(k,1) = classOrder{ai(k)};  % own orientation, not the index's), which
        combo(k,2) = classOrder{bi(k)};  % silently breaks a vectorized classOrder(ai) here
        combo(k,3) = classOrder{ci(k)};
    end
    margProb = cnt / total;
    condProb = zeros(size(cnt));
    for k = 1:numel(cnt)
        abTotal = sum(counts3(ai(k), bi(k), :));
        condProb(k) = cnt(k) / abTotal;
    end
end

function frac = transitionIntoFractions(seqs, nClass)
    % Per-sequence (per-cluster), the fraction of its actual class changes
    % that land on each class. Rows = clusters, columns = classes.
    % A cluster with < 2 compressed entries (no observed change) gets NaN.
    n = numel(seqs);
    frac = nan(n, nClass);
    for i = 1:n
        s = seqs{i};
        if numel(s) < 2; continue; end
        dest = s(2:end);
        dest = dest(dest >= 1 & dest <= nClass);
        if isempty(dest); continue; end
        for c = 1:nClass
            frac(i,c) = sum(dest == c) / numel(dest);
        end
    end
end

function [frac, pairs] = transitionPairFractions(seqs, nClass)
    % Per-cluster fraction of ALL its transitions that are specifically the
    % ordered pair i->j, for every i~=j (20 pairs for 5 classes). Unlike
    % transitionIntoFractions (which only looks at the destination class),
    % this keeps the FROM class fixed too, so "PIT->SADDLE" and "TROUGH->SADDLE"
    % are counted separately even though both "land on" SADDLE.
    pairs = [];
    for i = 1:nClass
        for j = 1:nClass
            if i ~= j
                pairs = [pairs; i j]; %#ok<AGROW>
            end
        end
    end
    nPairs = size(pairs, 1);
    n = numel(seqs);
    frac = nan(n, nPairs);
    for k = 1:n
        s = seqs{k};
        if numel(s) < 2; continue; end
        c1 = s(1:end-1); c2 = s(2:end);
        total = numel(c1);
        if total == 0; continue; end
        for p = 1:nPairs
            frac(k,p) = sum(c1 == pairs(p,1) & c2 == pairs(p,2)) / total;
        end
    end
end

function plotTransitionPairsVsRandom(seqsA, seqsB, nClass, classShort, classColors, ttl, fname, outFolder)
    % Grouped boxplot + Mann-Whitney, one group per SPECIFIC ordered
    % transition (e.g. PIT->SADDLE), TNFR1 vs. random -- finer-grained than
    % plotTransitionIntoClassVsRandom, which only checks the destination
    % class and would miss a difference that's specific to one FROM class.
    [fracA, pairs] = transitionPairFractions(seqsA, nClass);
    fracB = transitionPairFractions(seqsB, nClass);
    nPairs = size(pairs, 1);

    lbls = strings(nPairs, 1);
    for p = 1:nPairs
        lbls(p) = string(classShort{pairs(p,1)}) + " -> " + string(classShort{pairs(p,2)});
    end

    fig = figure('Color','w','Position',[80 120 1450 560]); hold on;
    posA = (1:nPairs) - 0.18;
    posB = (1:nPairs) + 0.18;
    allValsA = []; grpA = [];
    allValsB = []; grpB = [];
    for p = 1:nPairs
        v1 = fracA(:,p); v1 = v1(~isnan(v1));
        allValsA = [allValsA; v1]; grpA = [grpA; repmat(p, numel(v1), 1)]; %#ok<AGROW>
        v2 = fracB(:,p); v2 = v2(~isnan(v2));
        allValsB = [allValsB; v2]; grpB = [grpB; repmat(p, numel(v2), 1)]; %#ok<AGROW>
    end
    boxplot(allValsA, grpA, 'positions', posA, 'widths', 0.3, 'colors', classColors(1,:), 'symbol', '');
    boxplot(allValsB, grpB, 'positions', posB, 'widths', 0.3, 'colors', [0.55 0.55 0.55], 'symbol', '');
    set(gca, 'XTick', 1:nPairs, 'XTickLabel', lbls, 'XTickLabelRotation', 60, ...
        'XLim', [0.4 nPairs+0.6], 'TickLabelInterpreter', 'none');
    ylabel('fraction of that cluster''s transitions that are this specific pair');
    title(ttl, 'Interpreter','none');
    h1 = plot(nan,nan,'-','Color',classColors(1,:),'LineWidth',3);
    h2 = plot(nan,nan,'-','Color',[0.55 0.55 0.55],'LineWidth',3);
    legend([h1 h2], {'TNFR1 cluster','Random background'}, 'Location','northoutside', 'Orientation','horizontal');

    yl = ylim;
    From = strings(nPairs,1); To = strings(nPairs,1);
    TNFR1_mean_pct = nan(nPairs,1); Random_mean_pct = nan(nPairs,1); MannWhitney_p = nan(nPairs,1);
    for p = 1:nPairs
        v1 = fracA(:,p); v1 = v1(~isnan(v1));
        v2 = fracB(:,p); v2 = v2(~isnan(v2));
        if numel(v1) >= 3 && numel(v2) >= 3
            pv = ranksum(v1, v2);
        else
            pv = NaN;
        end
        stars = pToStars(pv);
        if ~isempty(stars)
            text(p, yl(2)*0.98, stars, 'HorizontalAlignment','center', 'FontSize',9, ...
                'FontWeight','bold', 'Color',[0.75 0.1 0.1], 'VerticalAlignment','top');
        end
        From(p) = string(classShort{pairs(p,1)});
        To(p) = string(classShort{pairs(p,2)});
        TNFR1_mean_pct(p) = 100*mean(v1,'omitnan');
        Random_mean_pct(p) = 100*mean(v2,'omitnan');
        MannWhitney_p(p) = pv;
    end
    results = table(From, To, TNFR1_mean_pct, Random_mean_pct, MannWhitney_p);
    writetable(results, fullfile(outFolder, [fname '.csv']));
    nSig = sum(MannWhitney_p < 0.05, 'omitnan');
    fprintf('  %s: %d / %d specific transitions differ from random at p<0.05 (full table in %s.csv)\n', ...
        fname, nSig, nPairs, fname);

    saveFigure(fig, fname, outFolder);
end

function plotTransitionIntoClassVsRandom(seqsA, seqsB, nClass, classShort, classColors, ttl, fname, outFolder)
    % Grouped boxplot: for each class, the per-cluster fraction of actual
    % class-changes landing on that class, TNFR1 (seqsA) vs. random (seqsB),
    % plus a per-class Mann-Whitney p-value.
    fracA = transitionIntoFractions(seqsA, nClass);
    fracB = transitionIntoFractions(seqsB, nClass);

    fig = figure('Color','w','Position',[100 100 820 480]); hold on;
    posA = (1:nClass) - 0.18;
    posB = (1:nClass) + 0.18;
    allValsA = []; grpA = [];
    allValsB = []; grpB = [];
    for c = 1:nClass
        v1 = fracA(:,c); v1 = v1(~isnan(v1));
        allValsA = [allValsA; v1]; grpA = [grpA; repmat(c, numel(v1), 1)]; %#ok<AGROW>
        v2 = fracB(:,c); v2 = v2(~isnan(v2));
        allValsB = [allValsB; v2]; grpB = [grpB; repmat(c, numel(v2), 1)]; %#ok<AGROW>
    end
    boxplot(allValsA, grpA, 'positions', posA, 'widths', 0.3, 'colors', classColors(1,:));
    boxplot(allValsB, grpB, 'positions', posB, 'widths', 0.3, 'colors', [0.55 0.55 0.55]);
    set(gca, 'XTick', 1:nClass, 'XTickLabel', classShort, 'XLim', [0.4 nClass+0.6]);
    ylabel('fraction of that cluster''s transitions landing on this class');
    title(ttl, 'Interpreter','none');
    h1 = plot(nan,nan,'-','Color',classColors(1,:),'LineWidth',3);
    h2 = plot(nan,nan,'-','Color',[0.55 0.55 0.55],'LineWidth',3);
    legend([h1 h2], {'TNFR1 cluster','Random background'}, 'Location','northoutside', 'Orientation','horizontal');
    yl = ylim;
    for c = 1:nClass
        v1 = fracA(:,c); v1 = v1(~isnan(v1));
        v2 = fracB(:,c); v2 = v2(~isnan(v2));
        if numel(v1) >= 3 && numel(v2) >= 3
            p = ranksum(v1, v2);
        else
            p = NaN;
        end
        text(c, yl(2)*0.98, sprintf('p=%.2g', p), 'HorizontalAlignment','center', 'FontSize',8, 'VerticalAlignment','top');
        fprintf('  %-12s TNFR1 mean=%.1f%%  Random mean=%.1f%%  Mann-Whitney p=%.3g\n', ...
            classShort{c}, 100*mean(v1,'omitnan'), 100*mean(v2,'omitnan'), p);
    end
    saveFigure(fig, fname, outFolder);
end

function saveFigure(fig, name, outFolder)
    exportgraphics(fig, fullfile(outFolder, [name '.png']), 'Resolution', 300); % print-quality
    exportgraphics(fig, fullfile(outFolder, [name '.pdf']));
    savefig(fig, fullfile(outFolder, [name '.fig']));
    close(fig);
end

function kwStat = boxplotByClass(vals, labels, classOrder, ttl, ylab, fname, outFolder)
    labels = string(labels);
    keep = ismember(labels, string(classOrder)) & ~isnan(vals);
    vals = vals(keep); labels = labels(keep);
    cats = categorical(labels, string(classOrder));
    fig = figure('Color','w','Position',[100 100 700 460]);
    boxplot(vals, cats);
    ylabel(ylab); title(ttl, 'Interpreter','none');
    [p, tbl] = kruskalwallis(vals, cats, 'off');
    H = tbl{2,5};
    text(0.02, 0.96, sprintf('Kruskal-Wallis H=%.1f, p=%.2g, n=%d', H, p, numel(vals)), ...
        'Units','normalized', 'FontWeight','bold', 'VerticalAlignment','top');
    saveFigure(fig, fname, outFolder);
    kwStat = struct('H',H,'p',p);
    fprintf('  %-45s H=%.1f p=%.2g\n', fname, H, p);
end

function scatterWithCorr(x, y, xlab, ylab, ttl, fname, outFolder)
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid); y = y(valid);
    fig = figure('Color','w','Position',[100 100 620 460]);
    scatter(x, y, 20, 'filled', 'MarkerFaceAlpha', 0.45); hold on;
    lsline;
    [r, p] = corr(x, y, 'Type','Spearman');
    xlabel(xlab); ylabel(ylab); title(ttl, 'Interpreter','none');
    text(0.02, 0.96, sprintf('Spearman r=%.2f, p=%.2g, n=%d', r, p, numel(x)), ...
        'Units','normalized', 'FontWeight','bold', 'VerticalAlignment','top');
    saveFigure(fig, fname, outFolder);
    fprintf('  %-45s r=%.2f p=%.2g\n', fname, r, p);
end

function scatterWithCorrTwoGroups(xA, yA, xB, yB, nameA, nameB, xlab, ylab, ttl, fname, outFolder)
    % Same scatter+fit-line+correlation as scatterWithCorr, but for two
    % groups overlaid on one axes, so the dependence can be compared directly
    % instead of read off two separate figures.
    %
    % Inputs are forced to column vectors: callers may pass struct-array
    % comma-list expansions like [S.field], which come out as ROW vectors --
    % corr() on two row vectors treats each element as its own "variable"
    % and silently returns an NxN matrix instead of a scalar, which then
    % blows up every downstream sprintf/fprintf/legend call that assumes a
    % scalar r/p.
    xA = xA(:); yA = yA(:); xB = xB(:); yB = yB(:);
    validA = ~isnan(xA) & ~isnan(yA); xA = xA(validA); yA = yA(validA);
    validB = ~isnan(xB) & ~isnan(yB); xB = xB(validB); yB = yB(validB);
    colorA = [0.16 0.47 0.84]; colorB = [0.55 0.55 0.55];

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

    % Correlations tell you whether EACH group has a relationship, but not
    % whether the groups themselves differ -- add a direct Mann-Whitney
    % test on the y-variable (and on x, since SDt/Tension itself can differ
    % too) so "is random different from TNFR1" always has an explicit answer.
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

    saveFigure(fig, fname, outFolder);
    fprintf('  %-45s %s: r=%.2f p=%.2g (n=%d)   %s: r=%.2f p=%.2g (n=%d)   [MW x: p=%.3g, MW y: p=%.3g]\n', ...
        fname, nameA, rA, pA, numel(xA), nameB, rB, pB, numel(xB), pmwX, pmwY);
end

function cmap = divergingColormap(n)
    n1 = ceil(n/2); n2 = n - n1;
    top = [linspace(0.12,1,n1)' linspace(0.47,1,n1)' linspace(0.71,1,n1)'];
    bot = [linspace(1,0.84,n2)' linspace(1,0.15,n2)' linspace(1,0.16,n2)'];
    cmap = [top; bot];
end

function stratifiedCorrHeatmap(x, y, labels, classOrder, ttl, fname, outFolder)
    % Spearman r (x vs. y) computed once pooled across everything, then again
    % restricted to each class in turn, displayed as a single-column heatmap
    % (one row per group) so a class-specific relationship is visible even if
    % it's diluted or absent in the pooled figure.
    labels = string(labels);
    rowNames = [{'Pooled'}, classOrder];
    nRows = numel(rowNames);
    R = nan(nRows,1); P = nan(nRows,1); N = zeros(nRows,1);
    for k = 1:nRows
        if k == 1
            mask = true(size(x));
        else
            mask = labels == string(classOrder{k-1});
        end
        xi = x(mask); yi = y(mask);
        valid = ~isnan(xi) & ~isnan(yi);
        xi = xi(valid); yi = yi(valid);
        N(k) = numel(xi);
        if N(k) >= 4
            [r,p] = corr(xi, yi, 'Type','Spearman');
            R(k) = r; P(k) = p;
        end
    end

    fig = figure('Color','w','Position',[100 100 380 460]);
    imagesc(R); colormap(divergingColormap(256)); caxis([-1 1]); colorbar;
    set(gca,'XTick',1,'XTickLabel',{'SDt vs. curvature'}, ...
        'YTick',1:nRows,'YTickLabel',rowNames, 'TickLabelInterpreter','none');
    for k = 1:nRows
        if isnan(R(k))
            lbl = sprintf('n=%d\n(too few)', N(k));
        else
            txtColor = 'k'; if abs(R(k)) > 0.6; txtColor = 'w'; end
            lbl = sprintf('r=%.2f%s\nn=%d', R(k), pToStars(P(k)), N(k));
        end
        if isnan(R(k)); txtColor = 'k'; end
        text(1, k, lbl, 'HorizontalAlignment','center', 'FontSize',8, 'Color', txtColor);
    end
    title(ttl, 'Interpreter','none', 'FontSize',9);
    annotation('textbox', [0.05 0.005 0.9 0.04], ...
        'String', '* p<0.05    ** p<0.01    *** p<0.001', ...
        'EdgeColor','none', 'HorizontalAlignment','center', 'FontSize',8, 'Color',[0.4 0.4 0.4]);
    saveFigure(fig, fname, outFolder);

    fprintf('  %-45s pooled r=%.2f p=%.2g (n=%d)\n', fname, R(1), P(1), N(1));
    for k = 2:nRows
        fprintf('    %-15s r=%.2f p=%.2g (n=%d)\n', rowNames{k}, R(k), P(k), N(k));
    end
end

function corrHeatmap(dataMat, varNames, ttl, fname, outFolder)
    [R, P] = corr(dataMat, 'Type','Spearman', 'Rows','pairwise');
    n = numel(varNames);
    figSide = max(620, 44*n);   % scale with variable count so cells/text stay readable
    fig = figure('Color','w','Position',[100 100 figSide+80 figSide]);
    imagesc(R); axis square; colormap(divergingColormap(256)); colorbar; caxis([-1 1]);
    set(gca,'XTick',1:n,'XTickLabel',varNames,'XTickLabelRotation',45, ...
        'YTick',1:n,'YTickLabel',varNames, 'TickLabelInterpreter','none');
    for i = 1:n
        for j = 1:n
            txtColor = 'k';
            if abs(R(i,j)) > 0.6; txtColor = 'w'; end
            if i == j
                stars = '';   % self-correlation -- significance is not meaningful here
            else
                stars = pToStars(P(i,j));
            end
            text(j, i, sprintf('%.2f%s', R(i,j), stars), 'HorizontalAlignment','center', ...
                'FontSize', 8, 'Color', txtColor);
        end
    end
    title(ttl, 'Interpreter','none');
    annotation('textbox', [0.05 0.005 0.9 0.04], ...
        'String', '* p<0.05    ** p<0.01    *** p<0.001    (no marker = not significant)', ...
        'EdgeColor','none', 'HorizontalAlignment','center', 'FontSize',8, 'Color',[0.4 0.4 0.4]);
    saveFigure(fig, fname, outFolder);
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

function pct = classPctVector(labels, classOrder)
    labels = string(labels);
    nC = numel(classOrder);
    pct = zeros(1,nC);
    for ci = 1:nC
        pct(ci) = 100 * sum(labels == string(classOrder{ci})) / numel(labels);
    end
end

function barWithTwoSEM(meanVals, cellSEM, setSEM, labels, pooled, ttl, fname, outFolder)
    fig = figure('Color','w','Position',[100 100 700 460]);
    x = 1:numel(meanVals);
    bar(x, meanVals, 'FaceColor', [0.16 0.47 0.84]); hold on;
    errorbar(x-0.12, meanVals, cellSEM, 'k.', 'LineWidth',1.4, 'CapSize',8, 'LineStyle','none');
    errorbar(x+0.12, meanVals, setSEM, '.', 'Color',[0.85 0.33 0.10], 'LineWidth',1.4, 'CapSize',8, 'LineStyle','none');
    set(gca,'XTick',x,'XTickLabel',labels);
    for i = x
        text(i, meanVals(i)+cellSEM(i)+1.5, sprintf('%.1f%%',meanVals(i)), 'HorizontalAlignment','center','FontWeight','bold');
        text(i, -3, sprintf('pooled %.1f%%', pooled(i)), 'HorizontalAlignment','center','FontSize',8,'Color',[0.5 0.5 0.5]);
    end
    ylabel('% of clusters'); title(ttl, 'Interpreter','none');
    legend({'mean %','SEM (cells)','SEM (sets)'}, 'Location','northoutside', 'Orientation','horizontal');
    saveFigure(fig, fname, outFolder);
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
        ylim([yl(1), yl(2)*1.15]); % headroom for the significance annotations
        yl = ylim;
        for k = 1:numel(pvals)
            topY = max(pct1(k)+sem1(k), pct2(k)+sem2(k));
            stars = pToStars(pvals(k));
            if isempty(stars); stars = 'ns'; end
            text(k, topY + 0.035*range(yl), stars, 'HorizontalAlignment','center', ...
                'FontWeight','bold', 'FontSize',10);
        end
    end
    saveFigure(fig, fname, outFolder);
end

function boxplotTwoGroupsWhiskerScaled(vals1, vals2, name1, name2, ttl, ylab, fname, outFolder)
    vals1 = vals1(~isnan(vals1)); vals2 = vals2(~isnan(vals2));
    if isempty(vals1) || isempty(vals2)
        fprintf('  %-45s skipped -- one group is empty (n1=%d, n2=%d)\n', fname, numel(vals1), numel(vals2));
        return
    end
    allvals = [vals1(:); vals2(:)];
    grp = [repmat({name1}, numel(vals1),1); repmat({name2}, numel(vals2),1)];
    fig = figure('Color','w','Position',[100 100 600 460]);
    boxplot(allvals, grp);
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
    saveFigure(fig, fname, outFolder);
    fprintf('  %-45s p=%.2g\n', fname, p);
end

function [allIv, allIvClass] = pooledIntervalsByClass(C)
    allIv = [];
    allIvClass = strings(0,1);
    for i = 1:numel(C)
        iv = C(i).Intervals;
        if isempty(iv); continue; end
        allIv = [allIv; iv(:)]; %#ok<AGROW>
        allIvClass = [allIvClass; repmat(C(i).ClassSnapshot, numel(iv), 1)]; %#ok<AGROW>
    end
end

function counts = countByClass(labels, classOrder)
    labels = string(labels);
    counts = zeros(1, numel(classOrder));
    for ci = 1:numel(classOrder)
        counts(ci) = sum(labels == string(classOrder{ci}));
    end
end

function p = chiSquareTest(countsA, countsB)
    % Chi-square test of homogeneity on a 2xK contingency table (two group's
    % class-count distributions) -- are the two class MIXES different, not
    % just different in overall size.
    obs = [countsA(:)'; countsB(:)'];
    rowSum = sum(obs, 2); colSum = sum(obs, 1); total = sum(obs(:));
    expected = rowSum * colSum / total;
    valid = expected(:) > 0;
    chi2stat = sum((obs(valid) - expected(valid)).^2 ./ expected(valid));
    dof = (size(obs,1)-1) * (sum(colSum > 0) - 1);
    if dof < 1 || total == 0
        p = NaN;
    else
        p = 1 - chi2cdf(chi2stat, dof);
    end
end

function plotGrouped3Series(pctA, nA, pctB, nB, pctC, nC, labels, nameA, nameB, nameC, ttl, ylab, fname, outFolder)
    % Grouped bar, 3 series, with binomial-proportion SE error bars (these
    % are pooled percentages from a single sample each, not per-cell means,
    % since the long-lived subsets are too small for per-cell SEM).
    n = numel(labels);
    fig = figure('Color','w','Position',[100 100 780 480]); hold on;
    b = bar([pctA(:) pctB(:) pctC(:)], 'grouped');
    semA = sqrt(pctA(:).*(100-pctA(:))/max(nA,1));
    semB = sqrt(pctB(:).*(100-pctB(:))/max(nB,1));
    semC = sqrt(pctC(:).*(100-pctC(:))/max(nC,1));
    errorbar(b(1).XEndPoints, pctA(:), semA, 'k.', 'LineWidth',1, 'CapSize',5, 'LineStyle','none');
    errorbar(b(2).XEndPoints, pctB(:), semB, 'k.', 'LineWidth',1, 'CapSize',5, 'LineStyle','none');
    errorbar(b(3).XEndPoints, pctC(:), semC, 'k.', 'LineWidth',1, 'CapSize',5, 'LineStyle','none');
    set(gca, 'XTick', 1:n, 'XTickLabel', labels);
    ylabel(ylab); title(ttl, 'Interpreter','none', 'FontSize',10);
    legend(b, {sprintf('%s (n=%d)',nameA,nA), sprintf('%s (n=%d)',nameB,nB), sprintf('%s (n=%d)',nameC,nC)}, ...
        'Location','northoutside', 'Orientation','horizontal');
    saveFigure(fig, fname, outFolder);
end

function boxplotByClassTwoGroups(valsA, labelsA, valsB, labelsB, classOrder, classShort, classColors, ttl, ylab, fname, outFolder)
    % Per-class grouped boxplot, two groups (e.g. TNFR1 vs. random), with a
    % Mann-Whitney p per class -- same visual pattern as the transition-pair
    % comparisons, generalized to a continuous value instead of a fraction.
    nClass = numel(classOrder);
    labelsA = string(labelsA); labelsB = string(labelsB);
    posA = (1:nClass) - 0.18;
    posB = (1:nClass) + 0.18;
    allValsA = []; grpA = [];
    allValsB = []; grpB = [];
    pvals = nan(1, nClass);
    for c = 1:nClass
        vA = valsA(labelsA == string(classOrder{c}) & ~isnan(valsA));
        vB = valsB(labelsB == string(classOrder{c}) & ~isnan(valsB));
        allValsA = [allValsA; vA(:)]; grpA = [grpA; repmat(c, numel(vA), 1)]; %#ok<AGROW>
        allValsB = [allValsB; vB(:)]; grpB = [grpB; repmat(c, numel(vB), 1)]; %#ok<AGROW>
        if numel(vA) >= 3 && numel(vB) >= 3
            pvals(c) = ranksum(vA, vB);
        end
    end

    fig = figure('Color','w','Position',[100 100 820 480]); hold on;
    boxplot(allValsA, grpA, 'positions', posA, 'widths', 0.3, 'colors', classColors(1,:));
    boxplot(allValsB, grpB, 'positions', posB, 'widths', 0.3, 'colors', [0.55 0.55 0.55]);
    set(gca, 'XTick', 1:nClass, 'XTickLabel', classShort, 'XLim', [0.4 nClass+0.6]);
    ylabel(ylab); title(ttl, 'Interpreter','none');
    h1 = plot(nan,nan,'-','Color',classColors(1,:),'LineWidth',3);
    h2 = plot(nan,nan,'-','Color',[0.55 0.55 0.55],'LineWidth',3);
    legend([h1 h2], {'TNFR1 cluster','Random background'}, 'Location','northoutside', 'Orientation','horizontal');

    % Scale off the whisker range, not the raw max -- a single extreme
    % outlier can otherwise compress every real box into an unreadable
    % sliver near zero (points beyond the clamp still exist in the data,
    % just off-scale, same as the boxplot's own outlier markers show).
    allvals = [allValsA; allValsB];
    if ~isempty(allvals)
        q = quantile(allvals, [0.25 0.75]);
        iqr_ = diff(q);
        hiWhisker = q(2) + 1.5*iqr_;
        loWhisker = q(1) - 1.5*iqr_;
        ymax = min(max(allvals), hiWhisker*1.3);
        ymin = max(min(allvals), loWhisker*1.3);
        if ymin == ymax; ymin = ymin - 1; ymax = ymax + 1; end
        ylim([ymin, ymax]);
    end
    yl = ylim;
    ylim([yl(1), yl(2) + 0.12*range(yl)]);
    yl = ylim;
    for c = 1:nClass
        stars = pToStars(pvals(c));
        if isempty(stars); stars = 'ns'; end
        text(c, yl(2)*0.98, stars, 'HorizontalAlignment','center', 'FontSize',9, 'VerticalAlignment','top');
    end
    saveFigure(fig, fname, outFolder);

    fprintf('  Classwise curvature, TNFR1 vs. random (Mann-Whitney per class):\n');
    for c = 1:nClass
        fprintf('    %-12s p=%.3g %s\n', classShort{c}, pvals(c), pToStars(pvals(c)));
    end
end

function transitionNetwork(codeCellArray, classOrder, classShort, ttlBase, fnameHeat, fnameNet, outFolder)
    nC = numel(classOrder);
    M = zeros(nC, nC);
    for i = 1:numel(codeCellArray)
        code = codeCellArray{i};
        code = code(~isnan(code));
        if numel(code) < 2; continue; end
        c1 = round(code(1:end-1)); c2 = round(code(2:end));
        valid = c1 >= 1 & c1 <= nC & c2 >= 1 & c2 <= nC;
        c1 = c1(valid); c2 = c2(valid);
        idx = sub2ind([nC nC], c1, c2);
        counts = accumarray(idx(:), 1, [nC*nC, 1]);
        M = M + reshape(counts, [nC, nC]);
    end

    rowSum = sum(M,2);
    rowSum(rowSum==0) = 1;
    Mprob = M ./ rowSum;

    fig1 = figure('Color','w','Position',[100 100 640 560]);
    imagesc(Mprob); axis square; colormap(parula); colorbar; caxis([0 1]);
    set(gca,'XTick',1:nC,'XTickLabel',classShort,'YTick',1:nC,'YTickLabel',classShort);
    for i = 1:nC
        for j = 1:nC
            txtColor = 'k';
            if Mprob(i,j) > 0.55; txtColor = 'w'; end
            text(j, i, sprintf('%.2f', Mprob(i,j)), 'HorizontalAlignment','center', 'FontSize',9, 'Color', txtColor);
        end
    end
    xlabel('to class (next frame)'); ylabel('from class (this frame)');
    title([ttlBase ' -- transition probability (row-normalized)'], 'Interpreter','none');
    saveFigure(fig1, fnameHeat, outFolder);

    Moff = M;
    Moff(1:nC+1:end) = 0;
    [s,t,w] = find(Moff);
    if isempty(s)
        fprintf('  %s: no off-diagonal transitions found, skipping network plot.\n', fnameNet);
        return;
    end
    G = digraph(s, t, w, classShort);
    fig2 = figure('Color','w','Position',[100 100 640 560]);
    lw = 1 + 5*(G.Edges.Weight / max(G.Edges.Weight));
    plot(G, 'Layout','circle', 'EdgeCData', G.Edges.Weight, 'LineWidth', lw, 'ArrowSize', 12, 'MarkerSize', 8);
    colormap(parula); colorbar;
    title([ttlBase ' -- transition network (self-transitions excluded)'], 'Interpreter','none');
    saveFigure(fig2, fnameNet, outFolder);
end
