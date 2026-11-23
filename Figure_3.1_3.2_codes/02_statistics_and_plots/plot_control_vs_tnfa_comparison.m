% NOTE (Figure 3.2 package): only the two SETUP lines below (controlFolder, tnfaFolder) differ from the original file.
% Figure 3.2 a-f compares CONTROL with ALL 84 TNFa clusters (run ..._20260812_203348).
% The original file pointed at the pre-existing-only run (25 clusters), which gives n2=25 and does NOT match the thesis.
%% plot_control_vs_tnfa_comparison.m
% Direct comparison of TNFR1 cluster behavior, Control vs. TNFa-treated,
% both from the raw (full 2048-frame, 5x-random, FBR-fixed) pipeline.
% This is a different comparison from plot_all_curvature_analyses.m's
% "TNFR1 vs. random background" -- here BOTH groups are real TNFR1 clusters,
% just from two different experimental conditions. Random-background points
% are not used in this script.
%
% Run this whole file (F5), or run section-by-section with Ctrl+Enter.

clear; clc; close all;
if ~usejava('desktop') || ~feature('ShowFigureWindows')
    set(0,'DefaultFigureVisible','off');  % headless/batch runs only
end

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
controlFolder = '/Volumes/T7 Touch/Forcurvature/with_good_cells/set7/Plate8/Exported/Curvature_Analysis_Output_20260807_094538';
tnfaFolder    = '/Volumes/T7 Touch/Forcurvature/For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260812_203348';

cd(controlFolder);
outFolder = fullfile(fileparts(fileparts(controlFolder)), ...
    sprintf('MATLAB_Control_vs_TNFa_%s', datestr(now,'yyyymmdd_HHMMSS')));
% Fall back to saving next to the control data if the folder-up trick above
% doesn't land somewhere writable (e.g. differing directory depths).
if ~exist(fileparts(outFolder), 'dir')
    outFolder = fullfile(controlFolder, sprintf('MATLAB_Control_vs_TNFa_%s', datestr(now,'yyyymmdd_HHMMSS')));
end
mkdir(outFolder);
fprintf('Saving all figures to:\n  %s\n\n', outFolder);

classOrder  = {'CUP / PIT','TROUGH','SADDLE','RIDGE','DOME / HILL'};
classShort  = {'CUP/PIT','TROUGH','SADDLE','RIDGE','DOME/HILL'};
nClass      = numel(classOrder);
classColors = [0.16 0.47 0.84; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.93 0.69 0.13; 0.49 0.18 0.56];
colorCtrl = [0.16 0.47 0.84];   % blue  -- Control
colorTnfa = [0.85 0.33 0.10];   % orange -- TNFa (distinct from the gray used for random-background elsewhere)

%% ================= LOAD BOTH DATASETS (raw runs, TNFR1 clusters only) =================
cd(controlFolder);
Sc = load('AllCells_CurvatureTopology_TimeSeries.mat', 'Tcombined', 'Allstats');
Tc = Sc.Tcombined;
TtnfrCtrl = Tc(strcmp(string(Tc.RegionType),'TNFR1_cluster'), :);
Cctrl = flattenClusterStats(Sc.Allstats, classOrder);
TCctrl = struct2table(rmfield(Cctrl, {'Intervals','ClassCode'}));
fprintf('Control: %d TNFR1 clusters (%d cells)\n', height(TtnfrCtrl), numel(unique(TtnfrCtrl.CellID)));

cd(tnfaFolder);
St = load('AllCells_CurvatureTopology_TimeSeries.mat', 'Tcombined', 'Allstats');
Tt = St.Tcombined;
TtnfrTnfa = Tt(strcmp(string(Tt.RegionType),'TNFR1_cluster'), :);
Ctnfa = flattenClusterStats(St.Allstats, classOrder);
TCtnfa = struct2table(rmfield(Ctnfa, {'Intervals','ClassCode'}));
fprintf('TNFa:    %d TNFR1 clusters (%d cells)\n\n', height(TtnfrTnfa), numel(unique(TtnfrTnfa.CellID)));

cd(controlFolder);  % back to a stable cwd for any relative-path helper calls

%% ================= N1/N2: class mix and curvature-by-class =================
fprintf('--- Class mix and curvature-by-class, Control vs. TNFa ---\n');

[pctCtrl, semCtrl, ~, ~, pctMatCtrl] = classPercentBySEM(string(TtnfrCtrl.Classification), TtnfrCtrl.CellID, classOrder);
[pctTnfa, semTnfa, ~, ~, pctMatTnfa] = classPercentBySEM(string(TtnfrTnfa.Classification), TtnfrTnfa.CellID, classOrder);

classPvals = nan(1,nClass);
for c = 1:nClass
    v1 = pctMatCtrl(:,c); v1 = v1(~isnan(v1));
    v2 = pctMatTnfa(:,c); v2 = v2(~isnan(v2));
    if numel(v1) >= 3 && numel(v2) >= 3
        classPvals(c) = ranksum(v1, v2);
    end
end
fprintf('  Class mix significance (Mann-Whitney on per-cell %%, Control vs. TNFa):\n');
for c = 1:nClass
    fprintf('    %-12s p=%.3g %s\n', classShort{c}, classPvals(c), pToStars(classPvals(c)));
end

groupedBarTwoSeries(pctCtrl, semCtrl, pctTnfa, semTnfa, classShort, 'Control','TNFa', ...
    'Class mix: Control vs. TNFa (mean % +/- SEM over cells)', '% of TNFR1 clusters', ...
    'N1_classmix_control_vs_tnfa', outFolder, classPvals);

boxplotByClassTwoGroups(TtnfrCtrl.MeanCurvature, string(TtnfrCtrl.Classification), ...
    TtnfrTnfa.MeanCurvature, string(TtnfrTnfa.Classification), classOrder, classShort, {colorCtrl}, ...
    'Mean curvature by class: Control (blue) vs. TNFa (orange)', 'Mean curvature', ...
    'N2_curvature_by_class_control_vs_tnfa', outFolder, colorCtrl, colorTnfa, 'Control', 'TNFa');

%% ================= N3-N7: overall distribution comparisons =================
fprintf('--- Overall distributions, Control vs. TNFa ---\n');

twoGroupBox(TCctrl.SDt, TCtnfa.SDt, 'Control','TNFa', ...
    'FBR SDt: Control vs. TNFa', 'Mean FBR SDt', 'N3_SDt_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

twoGroupBox(TCctrl.Tension, TCtnfa.Tension, 'Control','TNFa', ...
    'FBR Tension: Control vs. TNFa', 'Mean FBR Tension', 'N4_Tension_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

twoGroupBox(TtnfrCtrl.SD_MeanCurvature_AllFrames, TtnfrTnfa.SD_MeanCurvature_AllFrames, 'Control','TNFa', ...
    'SD of mean curvature: Control vs. TNFa', 'SD of mean curvature (2048 frames)', ...
    'N5_SDcurvature_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

twoGroupBox(TtnfrCtrl.FracClassChanges_AllFrames, TtnfrTnfa.FracClassChanges_AllFrames, 'Control','TNFa', ...
    'Fraction of frames with a class change: Control vs. TNFa', 'Fraction of frames with a class change', ...
    'N6_FracClassChanges_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

twoGroupBox(TCctrl.NFlips, TCtnfa.NFlips, 'Control','TNFa', ...
    'Number of curvature sign flips: Control vs. TNFa', 'Sign flips over 2048 frames', ...
    'N7_NFlips_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

%% ================= N8-N13: SDt/Tension dependence, Control vs. TNFa overlaid =================
fprintf('--- SDt/Tension dependence, Control vs. TNFa (does TNFa change the relationship itself?) ---\n');

scatterWithCorrTwoGroups(TCctrl.SDt, TCctrl.SD_MeanCurvature, TCtnfa.SDt, TCtnfa.SD_MeanCurvature, ...
    'Control', 'TNFa', 'Mean FBR SDt', 'SD of mean curvature', ...
    'SDt vs. SD of curvature: Control vs. TNFa', 'N8_SDt_vs_SDcurvature_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TCctrl.SDt, TCctrl.FracClassChanges, TCtnfa.SDt, TCtnfa.FracClassChanges, ...
    'Control', 'TNFa', 'Mean FBR SDt', 'Fraction of frames with a class change', ...
    'SDt vs. fraction of class changes: Control vs. TNFa', 'N9_SDt_vs_FracClassChanges_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TCctrl.SDt, TCctrl.NFlips, TCtnfa.SDt, TCtnfa.NFlips, ...
    'Control', 'TNFa', 'Mean FBR SDt', 'Number of sign flips', ...
    'SDt vs. sign-flip frequency: Control vs. TNFa', 'N10_SDt_vs_NFlips_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TCctrl.Tension, TCctrl.SD_MeanCurvature, TCtnfa.Tension, TCtnfa.SD_MeanCurvature, ...
    'Control', 'TNFa', 'Mean FBR Tension', 'SD of mean curvature', ...
    'Tension vs. SD of curvature: Control vs. TNFa', 'N11_Tension_vs_SDcurvature_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TCctrl.Tension, TCctrl.FracClassChanges, TCtnfa.Tension, TCtnfa.FracClassChanges, ...
    'Control', 'TNFa', 'Mean FBR Tension', 'Fraction of frames with a class change', ...
    'Tension vs. fraction of class changes: Control vs. TNFa', 'N12_Tension_vs_FracClassChanges_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TCctrl.Tension, TCctrl.NFlips, TCtnfa.Tension, TCtnfa.NFlips, ...
    'Control', 'TNFa', 'Mean FBR Tension', 'Number of sign flips', ...
    'Tension vs. sign-flip frequency: Control vs. TNFa', 'N13_Tension_vs_NFlips_control_vs_tnfa', outFolder);

%% ================= N14: positive vs. negative curvature =================
fprintf('--- Positive vs. negative mean curvature, Control vs. TNFa ---\n');

signOrder = {'Positive','Negative'};
signCtrl = repmat("Positive", height(TtnfrCtrl), 1); signCtrl(TtnfrCtrl.MeanCurvature < 0) = "Negative";
signTnfa = repmat("Positive", height(TtnfrTnfa), 1); signTnfa(TtnfrTnfa.MeanCurvature < 0) = "Negative";

[pctSignCtrl, semSignCtrl, ~, ~, pctMatSignCtrl] = classPercentBySEM(signCtrl, TtnfrCtrl.CellID, signOrder);
[pctSignTnfa, semSignTnfa, ~, ~, pctMatSignTnfa] = classPercentBySEM(signTnfa, TtnfrTnfa.CellID, signOrder);
signPvals = nan(1,2);
for c = 1:2
    v1 = pctMatSignCtrl(:,c); v1 = v1(~isnan(v1));
    v2 = pctMatSignTnfa(:,c); v2 = v2(~isnan(v2));
    if numel(v1) >= 3 && numel(v2) >= 3
        signPvals(c) = ranksum(v1, v2);
    end
end
groupedBarTwoSeries(pctSignCtrl, semSignCtrl, pctSignTnfa, semSignTnfa, signOrder, 'Control','TNFa', ...
    'Percentage of positive vs. negative mean curvature: Control vs. TNFa', '% of TNFR1 clusters', ...
    'N14_curvature_sign_control_vs_tnfa', outFolder, signPvals);

%% ================= N15: long-lived clusters =================
fprintf('--- Long-lived (rarely-flipping) clusters, Control vs. TNFa ---\n');

miC = TCctrl.MeanInterval; validC = ~isnan(miC);
qC = quantile(miC(validC), [0.25 0.75]); fenceC = qC(2) + 1.5*diff(qC);
LLctrl = false(height(TCctrl),1); LLctrl(validC) = miC(validC) > fenceC; LLctrl(~validC) = true;

miT = TCtnfa.MeanInterval; validT = ~isnan(miT);
qT = quantile(miT(validT), [0.25 0.75]); fenceT = qT(2) + 1.5*diff(qT);
LLtnfa = false(height(TCtnfa),1); LLtnfa(validT) = miT(validT) > fenceT; LLtnfa(~validT) = true;

fprintf('  Long-lived fraction: Control %d/%d, TNFa %d/%d\n', sum(LLctrl), numel(LLctrl), sum(LLtnfa), numel(LLtnfa));

pLLctrl = 100*sum(LLctrl)/numel(LLctrl); pLLtnfa = 100*sum(LLtnfa)/numel(LLtnfa);
[~, pLLchi] = deal(NaN, chiSquareTest([sum(LLctrl), numel(LLctrl)-sum(LLctrl)], [sum(LLtnfa), numel(LLtnfa)-sum(LLtnfa)]));
fig = figure('Color','w','Position',[100 100 420 460]); hold on;
bar([1 2], [pLLctrl pLLtnfa], 'FaceColor','flat', 'CData',[colorCtrl; colorTnfa]);
set(gca,'XTick',[1 2],'XTickLabel',{'Control','TNFa'});
ylabel('% of TNFR1 clusters flagged long-lived');
title(sprintf('Long-lived cluster fraction: Control vs. TNFa (chi2 p=%.2g)', pLLchi), 'Interpreter','none', 'FontSize',10);
saveFigure(fig, 'N15a_longlived_fraction_control_vs_tnfa', outFolder);

twoGroupBox(TCctrl.Tension(LLctrl), TCtnfa.Tension(LLtnfa), 'Control','TNFa', ...
    'FBR Tension of long-lived clusters: Control vs. TNFa', 'Mean FBR Tension', ...
    'N15b_longlived_Tension_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

%% ================= N16-N19: does intensity's dependence on SDt/Tension change with TNFa? =================
% Paired entirely from Ttnfr's own T-table columns (Mean_FBR_SDt/Tension are
% available there directly, same as MeanIntensity/TotalIntensity) so there's
% no cross-table row-alignment risk.
fprintf('--- Intensity vs. SDt/Tension, Control vs. TNFa ---\n');

scatterWithCorrTwoGroups(TtnfrCtrl.Mean_FBR_SDt, TtnfrCtrl.MeanIntensity, TtnfrTnfa.Mean_FBR_SDt, TtnfrTnfa.MeanIntensity, ...
    'Control', 'TNFa', 'Mean FBR SDt', 'Mean intensity', ...
    'SDt vs. mean intensity: Control vs. TNFa', 'N16_SDt_vs_MeanIntensity_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TtnfrCtrl.Mean_FBR_Tension, TtnfrCtrl.MeanIntensity, TtnfrTnfa.Mean_FBR_Tension, TtnfrTnfa.MeanIntensity, ...
    'Control', 'TNFa', 'Mean FBR Tension', 'Mean intensity', ...
    'Tension vs. mean intensity: Control vs. TNFa', 'N17_Tension_vs_MeanIntensity_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TtnfrCtrl.Mean_FBR_SDt, TtnfrCtrl.TotalIntensity, TtnfrTnfa.Mean_FBR_SDt, TtnfrTnfa.TotalIntensity, ...
    'Control', 'TNFa', 'Mean FBR SDt', 'Total intensity', ...
    'SDt vs. total intensity: Control vs. TNFa', 'N18_SDt_vs_TotalIntensity_control_vs_tnfa', outFolder);

scatterWithCorrTwoGroups(TtnfrCtrl.Mean_FBR_Tension, TtnfrCtrl.TotalIntensity, TtnfrTnfa.Mean_FBR_Tension, TtnfrTnfa.TotalIntensity, ...
    'Control', 'TNFa', 'Mean FBR Tension', 'Total intensity', ...
    'Tension vs. total intensity: Control vs. TNFa', 'N19_Tension_vs_TotalIntensity_control_vs_tnfa', outFolder);

%% ================= N20/N21: pooled mean curvature, and curvature magnitude by class =================
fprintf('--- Mean curvature (pooled, and by class magnitude), Control vs. TNFa ---\n');

twoGroupBox(TtnfrCtrl.MeanCurvature, TtnfrTnfa.MeanCurvature, 'Control','TNFa', ...
    'Mean curvature, all TNFR1 clusters pooled: Control vs. TNFa', 'Mean curvature', ...
    'N20_MeanCurvature_pooled_control_vs_tnfa', outFolder, colorCtrl, colorTnfa);

% |curvature| answers "more curved" unambiguously -- signed MeanCurvature
% mixes concave/convex clusters, so a signed comparison alone can't say
% whether a class is more or less curved in magnitude.
boxplotByClassTwoGroups(abs(TtnfrCtrl.MeanCurvature), string(TtnfrCtrl.Classification), ...
    abs(TtnfrTnfa.MeanCurvature), string(TtnfrTnfa.Classification), classOrder, classShort, {colorCtrl}, ...
    '|Mean curvature| by class: Control (blue) vs. TNFa (orange) -- magnitude, not sign', '|Mean curvature|', ...
    'N21_abs_curvature_by_class_control_vs_tnfa', outFolder, colorCtrl, colorTnfa, 'Control', 'TNFa');

fprintf('\nAll done. %d figures saved to:\n  %s\n', numel(dir(fullfile(outFolder,'*.png'))), outFolder);


%% ================= LOCAL HELPER FUNCTIONS =================
% (Duplicated from plot_all_curvature_analyses.m so this script is
% self-contained -- MATLAB local functions aren't shared across script files.)

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
        while iscell(entry) && numel(entry) == 1
            entry = entry{1};
        end
        if isempty(entry) || ~isstruct(entry); continue; end
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

function saveFigure(fig, name, outFolder)
    exportgraphics(fig, fullfile(outFolder, [name '.png']), 'Resolution', 300);
    exportgraphics(fig, fullfile(outFolder, [name '.pdf']));
    savefig(fig, fullfile(outFolder, [name '.fig']));
    close(fig);
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

function p = chiSquareTest(countsA, countsB)
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
    saveFigure(fig, fname, outFolder);
end

function boxplotByClassTwoGroups(valsA, labelsA, valsB, labelsB, classOrder, classShort, ~, ttl, ylab, fname, outFolder, colorA, colorB, nameA, nameB)
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
    boxplot(allValsA, grpA, 'positions', posA, 'widths', 0.3, 'colors', colorA);
    boxplot(allValsB, grpB, 'positions', posB, 'widths', 0.3, 'colors', colorB);
    set(gca, 'XTick', 1:nClass, 'XTickLabel', classShort, 'XLim', [0.4 nClass+0.6]);
    ylabel(ylab); title(ttl, 'Interpreter','none');
    h1 = plot(nan,nan,'-','Color',colorA,'LineWidth',3);
    h2 = plot(nan,nan,'-','Color',colorB,'LineWidth',3);
    legend([h1 h2], {nameA, nameB}, 'Location','northoutside', 'Orientation','horizontal');

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

    fprintf('  Classwise curvature, %s vs. %s (Mann-Whitney per class):\n', nameA, nameB);
    for c = 1:nClass
        fprintf('    %-12s p=%.3g %s\n', classShort{c}, pvals(c), pToStars(pvals(c)));
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
    saveFigure(fig, fname, outFolder);
    fprintf('  %-45s p=%.2g\n', fname, p);
end

function scatterWithCorrTwoGroups(xA, yA, xB, yB, nameA, nameB, xlab, ylab, ttl, fname, outFolder)
    xA = xA(:); yA = yA(:); xB = xB(:); yB = yB(:);
    validA = ~isnan(xA) & ~isnan(yA); xA = xA(validA); yA = yA(validA);
    validB = ~isnan(xB) & ~isnan(yB); xB = xB(validB); yB = yB(validB);
    colorA = [0.16 0.47 0.84]; colorB = [0.85 0.33 0.10];

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

    saveFigure(fig, fname, outFolder);
    fprintf('  %-45s %s: r=%.2f p=%.2g (n=%d)   %s: r=%.2f p=%.2g (n=%d)   [MW x: p=%.3g, MW y: p=%.3g]\n', ...
        fname, nameA, rA, pA, numel(xA), nameB, rB, pB, numel(xB), pmwX, pmwY);
end
