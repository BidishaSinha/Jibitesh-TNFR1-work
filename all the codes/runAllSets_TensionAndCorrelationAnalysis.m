function batchResult = runAllSets_TensionAndCorrelationAnalysis(parentDir, outputRoot, opts)
% runAllSets_TensionAndCorrelationAnalysis Run tension KDE and pooled correlations for Set* folders.
%
% Expected folder layout:
%   Folder containing this .m file/
%       Set1/
%       Set2/
%       ...
%       SetN/
%
% Each Set folder may contain MAT files directly, or inside a full/ folder,
% or inside full.zip. The direct-folder layout is now the default.
%
% Example:
%   batchResult = runAllSets_TensionAndCorrelationAnalysis;
%
% This function calls:
%   runSet1_TensionKDE
%   runSet1_PooledPunctaCorrelations
%
% Despite their names, those two functions accept any set when setLabel is
% passed in. This batch runner supplies setLabel = 'set1', 'set2', ...

arguments
    parentDir (1,:) char = fileparts(mfilename('fullpath'))
    outputRoot (1,:) char = ''
    opts.setNames (1,:) cell = {}
    opts.inputFolderName (1,:) char = 'full'
    opts.inputZipName (1,:) char = 'full.zip'
    opts.runKDE (1,1) logical = true
    opts.runCorrelations (1,1) logical = true
    opts.continueOnError (1,1) logical = true
    opts.minWholeN (1,1) double = 20
    opts.minPunctaN (1,1) double = 3
    opts.gridN (1,1) double = 200
    opts.gridPercentiles (1,2) double = [1 99]
    opts.makePerCellPlot (1,1) logical = true
    opts.mannWhitneyMetric (1,:) char = 'median'
    opts.correlationMinN (1,1) double = 3
end

if isempty(outputRoot)
    outputRoot = fullfile(parentDir, 'all_sets_analysis_output');
end

if ~exist(outputRoot, 'dir')
    mkdir(outputRoot);
end

runSummary = table();
kdeResults = struct();
correlationResults = struct();

setNames = opts.setNames;
if isempty(setNames)
    setNames = discoverSetFolders(parentDir);
end

if isempty(setNames)
    error('No Set* folders found in %s', parentDir);
end

for i = 1:numel(setNames)
    setName = setNames{i};
    setLabel = char(setName);
    fprintf('Running %s...\n', setLabel);

    status = "OK";
    message = "";
    inputPath = "";
    kdeOutputDir = "";
    corrOutputDir = "";

    try
        inputPath = resolveSetInput(parentDir, setLabel, opts.inputFolderName, opts.inputZipName);
        setOutputDir = fullfile(outputRoot, setLabel);

        if ~exist(setOutputDir, 'dir')
            mkdir(setOutputDir);
        end

        if opts.runKDE
            kdeOutputDir = fullfile(setOutputDir, 'tension_kde_output');
            kdeResults.(matlab.lang.makeValidName(setLabel)) = runSet1_TensionKDE( ...
                char(inputPath), kdeOutputDir, ...
                'setLabel', setLabel, ...
                'minWholeN', opts.minWholeN, ...
                'minPunctaN', opts.minPunctaN, ...
                'gridN', opts.gridN, ...
                'gridPercentiles', opts.gridPercentiles, ...
                'makePerCellPlot', opts.makePerCellPlot, ...
                'mannWhitneyMetric', opts.mannWhitneyMetric);
        end

        if opts.runCorrelations
            corrOutputDir = fullfile(setOutputDir, 'pooled_puncta_correlation_output');
            correlationResults.(matlab.lang.makeValidName(setLabel)) = runSet1_PooledPunctaCorrelations( ...
                char(inputPath), corrOutputDir, ...
                'setLabel', setLabel, ...
                'minN', opts.correlationMinN);
        end
    catch ME
        status = "ERROR";
        message = string(ME.message);
        warning('Failed on %s: %s', setLabel, ME.message);

        if ~opts.continueOnError
            rethrow(ME);
        end
    end

    runSummary = [runSummary; table(string(setLabel), string(inputPath), ...
        string(kdeOutputDir), string(corrOutputDir), status, message, ...
        'VariableNames', {'SetName', 'InputPath', 'KDEOutputDir', ...
        'CorrelationOutputDir', 'Status', 'Message'})]; %#ok<AGROW>
end

batchResult = struct();
batchResult.ParentDir = parentDir;
batchResult.OutputRoot = outputRoot;
batchResult.Options = opts;
batchResult.RunSummary = runSummary;
batchResult.KDEResults = kdeResults;
batchResult.CorrelationResults = correlationResults;

save(fullfile(outputRoot, 'all_sets_batch_result.mat'), 'batchResult');
writetable(runSummary, fullfile(outputRoot, 'all_sets_run_summary.csv'));

fprintf('Done. Batch outputs saved in:\n%s\n', outputRoot);
end

function inputPath = resolveSetInput(parentDir, setName, inputFolderName, inputZipName)
setDir = findSetDirectory(parentDir, setName);

zipPath = fullfile(setDir, inputZipName);
folderPath = fullfile(setDir, inputFolderName);

matFilesDirect = dir(fullfile(setDir, '*.mat'));
if ~isempty(matFilesDirect)
    inputPath = string(setDir);
    return
end

if exist(zipPath, 'file')
    inputPath = string(zipPath);
    return
end

if exist(folderPath, 'dir') && ~isempty(dir(fullfile(folderPath, '*.mat')))
    inputPath = string(folderPath);
    return
end

error('Could not find MAT files directly in %s, or inside %s, or in %s', setDir, inputFolderName, inputZipName);
end

function setDir = findSetDirectory(parentDir, setName)
direct = fullfile(parentDir, setName);
if exist(direct, 'dir')
    setDir = direct;
    return
end

entries = dir(parentDir);
entries = entries([entries.isdir]);
entries = entries(~ismember({entries.name}, {'.', '..'}));

matchIdx = find(strcmpi({entries.name}, setName), 1);
if ~isempty(matchIdx)
    setDir = fullfile(parentDir, entries(matchIdx).name);
    return
end

error('Could not find set folder "%s" inside %s', setName, parentDir);
end

function setNames = discoverSetFolders(parentDir)
entries = dir(fullfile(parentDir, 'Set*'));
entries = entries([entries.isdir]);
entries = entries(~ismember({entries.name}, {'.', '..'}));

if isempty(entries)
    setNames = {};
    return
end

names = {entries.name};
setNumbers = nan(numel(names), 1);

for i = 1:numel(names)
    token = regexp(names{i}, '^Set(\d+)$', 'tokens', 'once', 'ignorecase');
    if ~isempty(token)
        setNumbers(i) = str2double(token{1});
    end
end

hasNumber = isfinite(setNumbers);
numberedNames = names(hasNumber);
numberedValues = setNumbers(hasNumber);
[~, order] = sort(numberedValues);
numberedNames = numberedNames(order);

otherNames = sort(names(~hasNumber));
setNames = [numberedNames, otherNames];
end
