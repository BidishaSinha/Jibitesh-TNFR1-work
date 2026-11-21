function result = runSet1_TensionKDE(set1Dir, outputDir, opts)
% runSet1_TensionKDE Compare whole-cell FBR tension vs puncta-localized tension.
%
% This function analyzes final workspace MAT files such as:
%   TNFR1_full_workspace_001.mat
%
% For each cell:
%   1. Extract all whole-cell tension values from fbrTen.
%   2. Extract puncta-localized tension values from ten.
%   3. Compute KDEs on a common x-grid.
%
% Then it averages KDE curves across cells and plots mean +/- SEM.
%
% Example with an extracted folder:
%   set1Dir = '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/allbaa/Set1/full';
%   outputDir = fullfile(set1Dir, 'tension_kde_output');
%   result = runSet1_TensionKDE(set1Dir, outputDir);
%
% Example with the zip file:
%   zipFile = '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/allbaa/Set1/full.zip';
%   outputDir = '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/allbaa/Set1/tension_kde_output';
%   result = runSet1_TensionKDE(zipFile, outputDir);
%
% Notes:
%   In MATLAB, the second column of fbrTen contains tension values.
%   The HDF5 storage view of v7.3 MAT files can appear transposed, so this
%   function defaults to fbrTen(:,2), not the HDF5-displayed row 2.

arguments
    set1Dir (1,:) char
    outputDir (1,:) char = fullfile(set1Dir, 'tension_kde_output')
    opts.filePattern (1,:) char = 'TNFR1_full_workspace_*.mat'
    opts.fbrTenVariable (1,:) char = 'fbrTen'
    opts.punctaTenVariable (1,:) char = 'ten'
    opts.fbrTenColumn (1,1) double = 2
    opts.fbrTenRow (1,1) double = NaN
    opts.gridN (1,1) double = 200
    opts.gridPercentiles (1,2) double = [1 99]
    opts.minWholeN (1,1) double = 20
    opts.minPunctaN (1,1) double = 3
    opts.bandwidth double = NaN
    opts.makePerCellPlot (1,1) logical = true
    opts.mannWhitneyMetric (1,:) char = 'median'
    opts.setLabel (1,:) char = 'Set1'
end

if endsWith(set1Dir, '.zip', 'IgnoreCase', true) && strcmp(outputDir, fullfile(set1Dir, 'tension_kde_output'))
    outputDir = fullfile(fileparts(set1Dir), 'tension_kde_output');
end

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

if endsWith(set1Dir, '.zip', 'IgnoreCase', true)
    unzipDir = fullfile(outputDir, 'unzipped_input');
    if ~exist(unzipDir, 'dir')
        mkdir(unzipDir);
        unzip(set1Dir, unzipDir);
    end
    inputDir = unzipDir;
else
    inputDir = set1Dir;
end

files = findMatFiles(inputDir, opts.filePattern);
if isempty(files)
    error('No files found in %s matching %s', inputDir, opts.filePattern);
end

cellData = struct([]);
allForGrid = [];

for i = 1:numel(files)
    matFile = fullfile(files(i).folder, files(i).name);
    cellID = erase(files(i).name, '.mat');

    [wholeVals, punctaVals] = loadCellTensionValues(matFile, opts);

    cellData(i).CellID = cellID;
    cellData(i).File = matFile;
    cellData(i).WholeTension = wholeVals;
    cellData(i).PunctaTension = punctaVals;
    cellData(i).NWholeFBR = numel(wholeVals);
    cellData(i).NPunctaTension = numel(punctaVals);
    cellData(i).UsedWhole = numel(wholeVals) >= opts.minWholeN;
    cellData(i).UsedPuncta = numel(punctaVals) >= opts.minPunctaN;

    allForGrid = [allForGrid; wholeVals(:); punctaVals(:)]; %#ok<AGROW>
end

allForGrid = allForGrid(isfinite(allForGrid));
if isempty(allForGrid)
    error('No finite tension values found.');
end

xGrid = buildCommonGrid(allForGrid, opts.gridPercentiles, opts.gridN);

nCells = numel(cellData);
wholePdf = nan(nCells, numel(xGrid));
punctaPdf = nan(nCells, numel(xGrid));

for i = 1:nCells
    if cellData(i).UsedWhole
        wholePdf(i,:) = computeKDE(cellData(i).WholeTension, xGrid, opts.bandwidth);
    end

    if cellData(i).UsedPuncta
        punctaPdf(i,:) = computeKDE(cellData(i).PunctaTension, xGrid, opts.bandwidth);
    end
end

[meanWhole, semWhole, nWholeAtGrid] = meanSemByGrid(wholePdf);
[meanPuncta, semPuncta, nPunctaAtGrid] = meanSemByGrid(punctaPdf);

cellSummary = buildCellSummary(cellData);
statsSummary = computePairedCellStats(cellData);
mannWhitney = computeMannWhitneyStats(cellSummary, opts.mannWhitneyMetric);
pooledMannWhitney = computePooledMannWhitneyStats(cellData);

result = struct();
result.SetLabel = opts.setLabel;
result.Options = opts;
result.XGrid = xGrid;
result.WholePdfByCell = wholePdf;
result.PunctaPdfByCell = punctaPdf;
result.MeanWhole = meanWhole;
result.SemWhole = semWhole;
result.MeanPuncta = meanPuncta;
result.SemPuncta = semPuncta;
result.NWholeAtGrid = nWholeAtGrid;
result.NPunctaAtGrid = nPunctaAtGrid;
result.CellSummary = cellSummary;
result.StatsSummary = statsSummary;
result.MannWhitney = mannWhitney;
result.PooledMannWhitney = pooledMannWhitney;

save(fullfile(outputDir, sprintf('%s_tension_kde_result.mat', opts.setLabel)), 'result');
writetable(cellSummary, fullfile(outputDir, sprintf('%s_cell_summary.csv', opts.setLabel)));
writetable(statsSummary, fullfile(outputDir, sprintf('%s_cell_stats.csv', opts.setLabel)));
writetable(struct2table(mannWhitney), fullfile(outputDir, sprintf('%s_mannwhitney_stats.csv', opts.setLabel)));
writetable(struct2table(pooledMannWhitney), fullfile(outputDir, sprintf('%s_pooled_mannwhitney_stats.csv', opts.setLabel)));

fig = plotWholeVsPunctaKDE(result);
savefig(fig, fullfile(outputDir, sprintf('%s_whole_vs_puncta_tension_kde.fig', opts.setLabel)));
exportgraphics(fig, fullfile(outputDir, sprintf('%s_whole_vs_puncta_tension_kde.png', opts.setLabel)), 'Resolution', 300);

if opts.makePerCellPlot
    fig2 = plotPerCellKDEs(result);
    savefig(fig2, fullfile(outputDir, sprintf('%s_per_cell_tension_kdes.fig', opts.setLabel)));
    exportgraphics(fig2, fullfile(outputDir, sprintf('%s_per_cell_tension_kdes.png', opts.setLabel)), 'Resolution', 300);

    fig3 = plotPunctaPerCellKDEs(result);
    savefig(fig3, fullfile(outputDir, sprintf('%s_puncta_per_cell_tension_kdes.fig', opts.setLabel)));
    exportgraphics(fig3, fullfile(outputDir, sprintf('%s_puncta_per_cell_tension_kdes.png', opts.setLabel)), 'Resolution', 300);
end
end

function files = findMatFiles(inputDir, filePattern)
files = dir(fullfile(inputDir, filePattern));
if ~isempty(files)
    return
end

subdirs = dir(inputDir);
subdirs = subdirs([subdirs.isdir]);
subdirs = subdirs(~ismember({subdirs.name}, {'.', '..'}));

files = [];
for i = 1:numel(subdirs)
    nested = dir(fullfile(inputDir, subdirs(i).name, filePattern));
    files = [files; nested]; %#ok<AGROW>
end
end

function [wholeVals, punctaVals] = loadCellTensionValues(matFile, opts)
varsToLoad = {opts.fbrTenVariable, opts.punctaTenVariable};
S = load(matFile, varsToLoad{:});

if ~isfield(S, opts.fbrTenVariable)
    error('Missing variable "%s" in %s', opts.fbrTenVariable, matFile);
end

fbrTen = S.(opts.fbrTenVariable);
if isvector(fbrTen)
    wholeVals = fbrTen(:);
else
    if ~isnan(opts.fbrTenRow)
        if size(fbrTen, 1) < opts.fbrTenRow
            error('fbrTen has %d rows, cannot use row %d in %s', size(fbrTen, 1), opts.fbrTenRow, matFile);
        end
        wholeVals = fbrTen(opts.fbrTenRow, :).';
    else
        if size(fbrTen, 2) < opts.fbrTenColumn
            error('fbrTen has %d columns, cannot use column %d in %s', size(fbrTen, 2), opts.fbrTenColumn, matFile);
        end
        wholeVals = fbrTen(:, opts.fbrTenColumn);
    end
end
wholeVals = cleanTensionVector(wholeVals);

if isfield(S, opts.punctaTenVariable)
    punctaVals = cleanTensionVector(S.(opts.punctaTenVariable));
else
    warning('Missing variable "%s" in %s. Using no puncta values.', opts.punctaTenVariable, matFile);
    punctaVals = [];
end
end

function vals = cleanTensionVector(vals)
vals = double(vals(:));
vals = vals(isfinite(vals));
vals = vals(vals > 0);
end

function xGrid = buildCommonGrid(vals, percentiles, gridN)
lo = prctile(vals, percentiles(1));
hi = prctile(vals, percentiles(2));

if ~isfinite(lo) || ~isfinite(hi) || lo == hi
    lo = min(vals);
    hi = max(vals);
end

if lo == hi
    pad = max(abs(lo) * 0.1, 1);
    lo = lo - pad;
    hi = hi + pad;
end

xGrid = linspace(lo, hi, gridN);
end

function pdfVals = computeKDE(vals, xGrid, bandwidth)
vals = cleanTensionVector(vals);

if isnan(bandwidth)
    pdfVals = ksdensity(vals, xGrid, 'Function', 'pdf', 'Support', 'positive');
else
    pdfVals = ksdensity(vals, xGrid, 'Function', 'pdf', 'Support', 'positive', 'Bandwidth', bandwidth);
end
end

function [m, sem, nAtGrid] = meanSemByGrid(pdfByCell)
nAtGrid = sum(isfinite(pdfByCell), 1);
m = mean(pdfByCell, 1, 'omitnan');
s = std(pdfByCell, 0, 1, 'omitnan');
sem = s ./ sqrt(nAtGrid);
sem(nAtGrid <= 1) = NaN;
end

function T = buildCellSummary(cellData)
n = numel(cellData);
CellID = strings(n, 1);
File = strings(n, 1);
NWholeFBR = zeros(n, 1);
NPunctaTension = zeros(n, 1);
UsedWhole = false(n, 1);
UsedPuncta = false(n, 1);
WholeMedian = nan(n, 1);
PunctaMedian = nan(n, 1);
WholeMean = nan(n, 1);
PunctaMean = nan(n, 1);

for i = 1:n
    CellID(i) = string(cellData(i).CellID);
    File(i) = string(cellData(i).File);
    NWholeFBR(i) = cellData(i).NWholeFBR;
    NPunctaTension(i) = cellData(i).NPunctaTension;
    UsedWhole(i) = cellData(i).UsedWhole;
    UsedPuncta(i) = cellData(i).UsedPuncta;

    if NWholeFBR(i) > 0
        WholeMedian(i) = median(cellData(i).WholeTension, 'omitnan');
        WholeMean(i) = mean(cellData(i).WholeTension, 'omitnan');
    end
    if NPunctaTension(i) > 0
        PunctaMedian(i) = median(cellData(i).PunctaTension, 'omitnan');
        PunctaMean(i) = mean(cellData(i).PunctaTension, 'omitnan');
    end
end

T = table(CellID, File, NWholeFBR, NPunctaTension, UsedWhole, UsedPuncta, ...
    WholeMean, PunctaMean, WholeMedian, PunctaMedian);
end

function T = computePairedCellStats(cellData)
n = numel(cellData);
CellID = strings(n, 1);
MeanDifference = nan(n, 1);
MedianDifference = nan(n, 1);
WholeHighFraction = nan(n, 1);
PunctaHighFraction = nan(n, 1);
HighTensionEnrichment = nan(n, 1);
Threshold75 = nan(n, 1);

for i = 1:n
    CellID(i) = string(cellData(i).CellID);
    wholeVals = cellData(i).WholeTension;
    punctaVals = cellData(i).PunctaTension;

    if isempty(wholeVals) || isempty(punctaVals)
        continue
    end

    MeanDifference(i) = mean(punctaVals, 'omitnan') - mean(wholeVals, 'omitnan');
    MedianDifference(i) = median(punctaVals, 'omitnan') - median(wholeVals, 'omitnan');

    Threshold75(i) = prctile(wholeVals, 75);
    WholeHighFraction(i) = mean(wholeVals >= Threshold75(i), 'omitnan');
    PunctaHighFraction(i) = mean(punctaVals >= Threshold75(i), 'omitnan');
    HighTensionEnrichment(i) = PunctaHighFraction(i) - WholeHighFraction(i);
end

T = table(CellID, MeanDifference, MedianDifference, Threshold75, ...
    WholeHighFraction, PunctaHighFraction, HighTensionEnrichment);
end

function stats = computeMannWhitneyStats(cellSummary, metric)
metric = lower(string(metric));

switch metric
    case "mean"
        wholeVals = cellSummary.WholeMean;
        punctaVals = cellSummary.PunctaMean;
        metricLabel = "per-cell mean tension";
    case "median"
        wholeVals = cellSummary.WholeMedian;
        punctaVals = cellSummary.PunctaMedian;
        metricLabel = "per-cell median tension";
    otherwise
        error('Unsupported mannWhitneyMetric "%s". Use "mean" or "median".', metric);
end

valid = cellSummary.UsedWhole & cellSummary.UsedPuncta & ...
    isfinite(wholeVals) & isfinite(punctaVals);

stats = struct();
stats.TestName = "Mann-Whitney U / ranksum";
stats.Metric = metric;
stats.MetricLabel = metricLabel;
stats.NWholeCells = sum(valid);
stats.NPunctaCells = sum(valid);
stats.PValue = NaN;
stats.RankSum = NaN;
stats.ZValue = NaN;
stats.Note = "Computed on cell-level summaries so cells, not puncta, are the statistical unit.";

if sum(valid) < 2
    stats.Note = stats.Note + " Not enough cells with both whole-cell and puncta summaries.";
    return
end

if exist('ranksum', 'file') ~= 2
    stats.Note = stats.Note + " MATLAB ranksum function was not found.";
    warning('ranksum was not found. Install/enable the Statistics and Machine Learning Toolbox to compute Mann-Whitney p-values.');
    return
end

[p, ~, rsStats] = ranksum(wholeVals(valid), punctaVals(valid));
stats.PValue = p;

if isfield(rsStats, 'ranksum')
    stats.RankSum = rsStats.ranksum;
end
if isfield(rsStats, 'zval')
    stats.ZValue = rsStats.zval;
end
end

function stats = computePooledMannWhitneyStats(cellData)
wholeVals = [];
punctaVals = [];

for i = 1:numel(cellData)
    wholeVals = [wholeVals; cellData(i).WholeTension(:)]; %#ok<AGROW>
    punctaVals = [punctaVals; cellData(i).PunctaTension(:)]; %#ok<AGROW>
end

wholeVals = cleanTensionVector(wholeVals);
punctaVals = cleanTensionVector(punctaVals);

stats = struct();
stats.TestName = "Pooled Mann-Whitney U / ranksum";
stats.Metric = "all tension values pooled across cells";
stats.NWholeValues = numel(wholeVals);
stats.NPunctaValues = numel(punctaVals);
stats.PValue = NaN;
stats.RankSum = NaN;
stats.ZValue = NaN;
stats.Note = "Pooled test combines all FBR values and puncta values across cells; cells with more observations contribute more.";

if numel(wholeVals) < 1 || numel(punctaVals) < 1
    stats.Note = stats.Note + " Not enough values for pooled test.";
    return
end

if exist('ranksum', 'file') ~= 2
    stats.Note = stats.Note + " MATLAB ranksum function was not found.";
    warning('ranksum was not found. Install/enable the Statistics and Machine Learning Toolbox to compute pooled Mann-Whitney p-values.');
    return
end

[p, ~, rsStats] = ranksum(wholeVals, punctaVals);
stats.PValue = p;

if isfield(rsStats, 'ranksum')
    stats.RankSum = rsStats.ranksum;
end
if isfield(rsStats, 'zval')
    stats.ZValue = rsStats.zval;
end
end

function fig = plotWholeVsPunctaKDE(result)
fig = figure('Color', 'w', 'Name', [result.SetLabel ' tension KDE']);
ax = axes(fig);
hold(ax, 'on');

x = result.XGrid(:).';

plotShaded(ax, x, result.MeanWhole, result.SemWhole, [0.20 0.20 0.20], 0.18);
plotShaded(ax, x, result.MeanPuncta, result.SemPuncta, [0.80 0.10 0.10], 0.20);

hWhole = plot(ax, x, result.MeanWhole, 'Color', [0.10 0.10 0.10], 'LineWidth', 2);
hPuncta = plot(ax, x, result.MeanPuncta, 'Color', [0.75 0.05 0.05], 'LineWidth', 2);

nWhole = sum(result.CellSummary.UsedWhole);
nPuncta = sum(result.CellSummary.UsedPuncta);

xlabel(ax, 'Tension');
ylabel(ax, 'Density');
title(ax, sprintf('%s: whole-cell FBR vs puncta-localized tension', result.SetLabel), 'Interpreter', 'none');
legend(ax, [hWhole hPuncta], ...
    sprintf('Whole-cell FBR, n = %d cells', nWhole), ...
    sprintf('Puncta, n = %d cells', nPuncta), ...
    'Location', 'best');
addMannWhitneyText(ax, result.MannWhitney, result.PooledMannWhitney);
box(ax, 'off');
set(ax, 'FontName', 'Arial', 'FontSize', 11);
end

function fig = plotPerCellKDEs(result)
fig = figure('Color', 'w', 'Name', [result.SetLabel ' per-cell tension KDEs']);
ax = axes(fig);
hold(ax, 'on');

x = result.XGrid(:).';

for i = 1:size(result.WholePdfByCell, 1)
    if all(isnan(result.WholePdfByCell(i,:)))
        continue
    end
    plot(ax, x, result.WholePdfByCell(i,:), 'Color', [0.72 0.72 0.72], 'LineWidth', 0.8);
end

for i = 1:size(result.PunctaPdfByCell, 1)
    if all(isnan(result.PunctaPdfByCell(i,:)))
        continue
    end
    plot(ax, x, result.PunctaPdfByCell(i,:), 'Color', [0.95 0.55 0.55], 'LineWidth', 0.8);
end

plot(ax, x, result.MeanWhole, 'Color', [0.05 0.05 0.05], 'LineWidth', 2.5);
plot(ax, x, result.MeanPuncta, 'Color', [0.75 0.05 0.05], 'LineWidth', 2.5);

xlabel(ax, 'Tension');
ylabel(ax, 'Density');
title(ax, sprintf('%s: per-cell KDEs', result.SetLabel), 'Interpreter', 'none');
box(ax, 'off');
set(ax, 'FontName', 'Arial', 'FontSize', 11);
end

function fig = plotPunctaPerCellKDEs(result)
fig = figure('Color', 'w', 'Name', [result.SetLabel ' puncta per-cell tension KDEs']);
ax = axes(fig);
hold(ax, 'on');

x = result.XGrid(:).';
nCells = size(result.PunctaPdfByCell, 1);
colors = lines(max(nCells, 1));
plotHandles = gobjects(0);
plotLabels = strings(0, 1);

for i = 1:nCells
    y = result.PunctaPdfByCell(i,:);
    if all(isnan(y))
        continue
    end

    h = plot(ax, x, y, 'Color', colors(i,:), 'LineWidth', 1.2);
    plotHandles(end + 1) = h; %#ok<AGROW>
    plotLabels(end + 1, 1) = result.CellSummary.CellID(i); %#ok<AGROW>
end

hMean = plot(ax, x, result.MeanPuncta, 'Color', [0.70 0.00 0.00], 'LineWidth', 3);

xlabel(ax, 'Tension');
ylabel(ax, 'Density');
title(ax, sprintf('%s: puncta-localized tension KDEs by cell', result.SetLabel), 'Interpreter', 'none');
box(ax, 'off');
set(ax, 'FontName', 'Arial', 'FontSize', 11);

if ~isempty(plotHandles)
    legend(ax, [plotHandles hMean], [plotLabels; "Mean puncta"], ...
        'Location', 'best', 'Interpreter', 'none');
else
    legend(ax, hMean, "Mean puncta", 'Location', 'best', 'Interpreter', 'none');
end
end

function plotShaded(ax, x, y, err, color, alphaVal)
valid = isfinite(x) & isfinite(y) & isfinite(err);
if ~any(valid)
    return
end

xv = x(valid);
yv = y(valid);
ev = err(valid);

lower = yv - ev;
upper = yv + ev;
lower(lower < 0) = 0;

fill(ax, [xv fliplr(xv)], [lower fliplr(upper)], color, ...
    'FaceAlpha', alphaVal, 'EdgeColor', 'none');
end

function addMannWhitneyText(ax, cellStats, pooledStats)
if isempty(cellStats) || ~isfield(cellStats, 'PValue')
    return
end

if isfinite(cellStats.PValue)
    cellText = sprintf('Cell-level MW (%s): p = %.3g', char(cellStats.Metric), cellStats.PValue);
else
    cellText = sprintf('Cell-level MW (%s): p = n/a', char(cellStats.Metric));
end

if nargin >= 3 && ~isempty(pooledStats) && isfield(pooledStats, 'PValue')
    if isfinite(pooledStats.PValue)
        pooledText = sprintf('Pooled MW: p = %.3g', pooledStats.PValue);
    else
        pooledText = 'Pooled MW: p = n/a';
    end
    pText = sprintf('%s\n%s', cellText, pooledText);
else
    pText = cellText;
end

text(ax, 0.02, 0.96, pText, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'FontName', 'Arial', ...
    'FontSize', 10, ...
    'BackgroundColor', 'w', ...
    'EdgeColor', [0.85 0.85 0.85], ...
    'Margin', 4, ...
    'Interpreter', 'none');
end
