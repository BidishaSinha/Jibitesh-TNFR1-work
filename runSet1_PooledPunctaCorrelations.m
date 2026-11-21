function result = runSet1_PooledPunctaCorrelations(set1Dir, outputDir, opts)
% runSet1_PooledPunctaCorrelations Build pooled puncta correlations for Set1.
%
% This uses final workspace variables inspected in the Set1 files:
%   Tension-mapped puncta: areastuck, intstuck, ten
%   SD-mapped puncta:      areastuckb, intstuckb, sdt, sds
%
% Because tension and SD mappings can have different valid puncta counts,
% rows are kept separately and missing mechanics are left as NaN. Pairwise
% correlations then use only rows where both variables are valid.
%
% Example:
%   zipFile = '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/allbaa/Set1/full.zip';
%   result = runSet1_PooledPunctaCorrelations(zipFile);

arguments
    set1Dir (1,:) char
    outputDir (1,:) char = fullfile(set1Dir, 'pooled_puncta_correlation_output')
    opts.filePattern (1,:) char = 'TNFR1_full_workspace_*.mat'
    opts.setLabel (1,:) char = 'Set1'
    opts.minN (1,1) double = 3
    opts.correlationTypes (1,:) cell = {'Spearman', 'Pearson'}
end

if endsWith(set1Dir, '.zip', 'IgnoreCase', true) && strcmp(outputDir, fullfile(set1Dir, 'pooled_puncta_correlation_output'))
    outputDir = fullfile(fileparts(set1Dir), 'pooled_puncta_correlation_output');
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

pooledTable = table();
cellSummary = table();

for i = 1:numel(files)
    matFile = fullfile(files(i).folder, files(i).name);
    cellID = erase(files(i).name, '.mat');

    cellTable = loadCellPunctaCorrelationTable(matFile, cellID);
    pooledTable = [pooledTable; cellTable]; %#ok<AGROW>

    cellSummary = [cellSummary; summarizeCell(cellID, matFile, cellTable)]; %#ok<AGROW>
end

parameterNames = chooseCorrelationParameters(pooledTable);
correlationTables = struct();

for i = 1:numel(opts.correlationTypes)
    corrType = opts.correlationTypes{i};
    correlationTables.(corrType) = computePairwiseCorrelations(pooledTable, parameterNames, corrType, opts.minN);
end

result = struct();
result.SetLabel = opts.setLabel;
result.Options = opts;
result.PooledPunctaTable = pooledTable;
result.CellSummary = cellSummary;
result.ParameterNames = parameterNames;
result.Correlations = correlationTables;

save(fullfile(outputDir, sprintf('%s_pooled_puncta_correlation_result.mat', opts.setLabel)), 'result');
writetable(pooledTable, fullfile(outputDir, sprintf('%s_pooled_puncta_table.csv', opts.setLabel)));
writetable(cellSummary, fullfile(outputDir, sprintf('%s_pooled_puncta_cell_summary.csv', opts.setLabel)));

for i = 1:numel(opts.correlationTypes)
    corrType = opts.correlationTypes{i};
    writetable(correlationTables.(corrType), ...
        fullfile(outputDir, sprintf('%s_%s_pairwise_correlations.csv', opts.setLabel, lower(corrType))));
end

figHeat = plotCorrelationHeatmap(correlationTables.Spearman, parameterNames, opts.setLabel, 'Spearman');
savefig(figHeat, fullfile(outputDir, sprintf('%s_spearman_correlation_heatmap.fig', opts.setLabel)));
exportgraphics(figHeat, fullfile(outputDir, sprintf('%s_spearman_correlation_heatmap.png', opts.setLabel)), 'Resolution', 300);

figScatter = plotFeatureMechanicsScatters(pooledTable, opts.setLabel, opts.minN);
savefig(figScatter, fullfile(outputDir, sprintf('%s_feature_vs_mechanics_scatter.fig', opts.setLabel)));
exportgraphics(figScatter, fullfile(outputDir, sprintf('%s_feature_vs_mechanics_scatter.png', opts.setLabel)), 'Resolution', 300);
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

function T = loadCellPunctaCorrelationTable(matFile, cellID)
available = string({whos('-file', matFile).name});

tensionVars = ["areastuck", "intstuck", "ten"];
sdVars = ["areastuckb", "intstuckb", "sdt", "sds"];
varsToLoad = cellstr(unique([tensionVars(ismember(tensionVars, available)), sdVars(ismember(sdVars, available))]));

if isempty(varsToLoad)
    warning('No recognized puncta correlation variables found in %s', matFile);
    T = makeEmptyPunctaTable();
    return
end

S = load(matFile, varsToLoad{:});
T = table();

if all(isfield(S, cellstr(tensionVars)))
    area = cleanVector(S.areastuck);
    intensity = cleanVector(S.intstuck);
    tension = cleanVector(S.ten);
    n = min([numel(area), numel(intensity), numel(tension)]);

    if n > 0
        T = [T; makePunctaRows(cellID, "TensionMapped", area(1:n), intensity(1:n), tension(1:n), nan(n, 1), nan(n, 1))]; %#ok<AGROW>
    end
else
    warning('Missing one or more tension-mapped variables in %s', matFile);
end

if all(isfield(S, cellstr(sdVars)))
    area = cleanVector(S.areastuckb);
    intensity = cleanVector(S.intstuckb);
    sdt = cleanVector(S.sdt);
    sds = cleanVector(S.sds);
    n = min([numel(area), numel(intensity), numel(sdt), numel(sds)]);

    if n > 0
        T = [T; makePunctaRows(cellID, "SDMapped", area(1:n), intensity(1:n), nan(n, 1), sdt(1:n), sds(1:n))]; %#ok<AGROW>
    end
else
    warning('Missing one or more SD-mapped variables in %s', matFile);
end

if isempty(T)
    T = makeEmptyPunctaTable();
end
end

function T = makePunctaRows(cellID, mappingType, area, intensity, tension, sdt, sds)
n = numel(area);
CellID = repmat(string(cellID), n, 1);
MappingType = repmat(string(mappingType), n, 1);
PunctumLocalID = (1:n).';
Area = double(area(:));
MeanIntensity = double(intensity(:));
TotalIntensity = Area .* MeanIntensity;
Tension = double(tension(:));
SDt = double(sdt(:));
SDs = double(sds(:));

T = table(CellID, MappingType, PunctumLocalID, Area, MeanIntensity, ...
    TotalIntensity, Tension, SDt, SDs);
end

function T = makeEmptyPunctaTable()
T = table(strings(0,1), strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
    zeros(0,1), zeros(0,1), zeros(0,1), zeros(0,1), ...
    'VariableNames', {'CellID', 'MappingType', 'PunctumLocalID', 'Area', ...
    'MeanIntensity', 'TotalIntensity', 'Tension', 'SDt', 'SDs'});
end

function vals = cleanVector(vals)
vals = double(vals(:));
vals(~isfinite(vals)) = NaN;
end

function summary = summarizeCell(cellID, matFile, T)
CellID = string(cellID);
File = string(matFile);
NTensionMapped = sum(T.MappingType == "TensionMapped");
NSDMapped = sum(T.MappingType == "SDMapped");
NValidTension = sum(isfinite(T.Tension));
NValidSDt = sum(isfinite(T.SDt));
NValidSDs = sum(isfinite(T.SDs));

summary = table(CellID, File, NTensionMapped, NSDMapped, NValidTension, NValidSDt, NValidSDs);
end

function names = chooseCorrelationParameters(T)
candidateNames = ["Area", "MeanIntensity", "TotalIntensity", "Tension", "SDt", "SDs", "Circularity", "Eccentricity"];
names = strings(0, 1);

for i = 1:numel(candidateNames)
    if ismember(candidateNames(i), string(T.Properties.VariableNames))
        vals = T.(char(candidateNames(i)));
        if isnumeric(vals) && any(isfinite(vals))
            names(end + 1, 1) = candidateNames(i); %#ok<AGROW>
        end
    end
end
end

function C = computePairwiseCorrelations(T, parameterNames, corrType, minN)
nParams = numel(parameterNames);
rows = table();

for i = 1:nParams
    for j = i+1:nParams
        xName = parameterNames(i);
        yName = parameterNames(j);
        x = T.(char(xName));
        y = T.(char(yName));
        valid = isfinite(x) & isfinite(y);
        n = sum(valid);

        rho = NaN;
        p = NaN;
        if n >= minN
            [rho, p] = corr(x(valid), y(valid), 'Type', char(corrType), 'Rows', 'complete');
        end

        rows = [rows; table(string(corrType), xName, yName, n, rho, p, ...
            'VariableNames', {'CorrelationType', 'XParameter', 'YParameter', 'N', 'Rho', 'PValue'})]; %#ok<AGROW>
    end
end

C = rows;
end

function fig = plotCorrelationHeatmap(C, parameterNames, setLabel, corrType)
nParams = numel(parameterNames);
R = nan(nParams, nParams);

for i = 1:nParams
    R(i, i) = 1;
end

for k = 1:height(C)
    i = find(parameterNames == C.XParameter(k), 1);
    j = find(parameterNames == C.YParameter(k), 1);
    if isempty(i) || isempty(j)
        continue
    end
    R(i, j) = C.Rho(k);
    R(j, i) = C.Rho(k);
end

fig = figure('Color', 'w', 'Name', [setLabel ' ' corrType ' correlation heatmap']);
ax = axes(fig);
imagesc(ax, R, [-1 1]);
axis(ax, 'image');
colormap(ax, redBlueColormap(256));
cb = colorbar(ax);
cb.Label.String = [corrType ' rho'];

set(ax, 'XTick', 1:nParams, 'XTickLabel', parameterNames, ...
    'YTick', 1:nParams, 'YTickLabel', parameterNames, ...
    'TickLabelInterpreter', 'none', 'FontName', 'Arial', 'FontSize', 10);
xtickangle(ax, 45);
title(ax, sprintf('%s pooled puncta %s correlations', setLabel, corrType), 'Interpreter', 'none');
end

function fig = plotFeatureMechanicsScatters(T, setLabel, minN)
featureNames = ["Area", "MeanIntensity", "TotalIntensity"];
mechanicNames = ["Tension", "SDt", "SDs"];

pairs = strings(0, 2);
for i = 1:numel(featureNames)
    for j = 1:numel(mechanicNames)
        if ismember(featureNames(i), string(T.Properties.VariableNames)) && ...
                ismember(mechanicNames(j), string(T.Properties.VariableNames))
            pairs(end + 1, :) = [featureNames(i), mechanicNames(j)]; %#ok<AGROW>
        end
    end
end

fig = figure('Color', 'w', 'Name', [setLabel ' feature vs mechanics scatter']);
tiledlayout(fig, numel(featureNames), numel(mechanicNames), 'TileSpacing', 'compact', 'Padding', 'compact');

for k = 1:size(pairs, 1)
    xName = pairs(k, 1);
    yName = pairs(k, 2);
    x = T.(char(xName));
    y = T.(char(yName));
    valid = isfinite(x) & isfinite(y);
    n = sum(valid);

    ax = nexttile;
    scatter(ax, x(valid), y(valid), 18, 'filled', 'MarkerFaceAlpha', 0.45, ...
        'MarkerFaceColor', [0.20 0.35 0.75], 'MarkerEdgeColor', 'none');
    xlabel(ax, xName, 'Interpreter', 'none');
    ylabel(ax, yName, 'Interpreter', 'none');
    box(ax, 'off');
    set(ax, 'FontName', 'Arial', 'FontSize', 9);

    if n >= minN
        [rho, p] = corr(x(valid), y(valid), 'Type', 'Spearman', 'Rows', 'complete');
        title(ax, sprintf('n=%d, rho=%.2f, p=%.2g', n, rho, p), 'Interpreter', 'none');
    else
        title(ax, sprintf('n=%d', n), 'Interpreter', 'none');
    end
end

sgtitle(fig, sprintf('%s pooled puncta: feature vs mechanics', setLabel), 'Interpreter', 'none');
end

function cmap = redBlueColormap(n)
if nargin < 1
    n = 256;
end

half = floor(n / 2);
blue = [linspace(0, 1, half).' linspace(0, 1, half).' ones(half, 1)];
red = [ones(n - half, 1) linspace(1, 0, n - half).' linspace(1, 0, n - half).'];
cmap = [blue; red];
end
