function MasterPunctaTable = createMasterPunctaTableFromBatch(batchMatFile, outputMatFile, outputCsvFile)
% createMasterPunctaTableFromBatch Create MasterPunctaTable.mat from batch.mat.
%
% batch.mat is expected to contain:
%   batchResult.CorrelationResults.Set1.PooledPunctaTable
%   batchResult.CorrelationResults.Set2.PooledPunctaTable
%   ...
%
% Example:
%   batchMatFile = '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/batch.mat';
%   outputMatFile = '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/MasterPunctaTable.mat';
%   MasterPunctaTable = createMasterPunctaTableFromBatch(batchMatFile, outputMatFile);
%
% Optional CSV:
%   createMasterPunctaTableFromBatch(batchMatFile, outputMatFile, ...
%       '/Users/bidishasinha/Downloads/Jibitesh/TIRF_IRM/MasterPunctaTable.csv');

arguments
    batchMatFile (1,:) char
    outputMatFile (1,:) char = fullfile(fileparts(batchMatFile), 'MasterPunctaTable.mat')
    outputCsvFile (1,:) char = ''
end

S = load(batchMatFile, 'batchResult');
if ~isfield(S, 'batchResult')
    error('The file does not contain a variable named batchResult: %s', batchMatFile);
end

batchResult = S.batchResult;
if ~isfield(batchResult, 'CorrelationResults')
    error('batchResult does not contain CorrelationResults.');
end

correlationResults = batchResult.CorrelationResults;
setNames = fieldnames(correlationResults);

if isempty(setNames)
    error('batchResult.CorrelationResults does not contain any set fields.');
end

MasterPunctaTable = table();
setSummary = table();

for i = 1:numel(setNames)
    setName = setNames{i};
    setResult = correlationResults.(setName);

    if ~isfield(setResult, 'PooledPunctaTable')
        warning('Skipping %s: no PooledPunctaTable field.', setName);
        continue
    end

    punctaTable = setResult.PooledPunctaTable;
    if ~istable(punctaTable)
        warning('Skipping %s: PooledPunctaTable is not a table.', setName);
        continue
    end

    if height(punctaTable) == 0
        warning('Skipping %s: PooledPunctaTable is empty.', setName);
        continue
    end

    punctaTable = addOrUpdateSetColumn(punctaTable, setName);
    MasterPunctaTable = [MasterPunctaTable; punctaTable]; %#ok<AGROW>

    setSummary = [setSummary; summarizeSet(setName, punctaTable)]; %#ok<AGROW>
end

if isempty(MasterPunctaTable)
    error('No puncta rows were found in batchResult.CorrelationResults.');
end

save(outputMatFile, 'MasterPunctaTable', 'setSummary');

if ~isempty(outputCsvFile)
    writetable(MasterPunctaTable, outputCsvFile);
end

fprintf('Saved %d puncta rows from %d sets to:\n%s\n', ...
    height(MasterPunctaTable), height(setSummary), outputMatFile);
end

function T = addOrUpdateSetColumn(T, setName)
setValues = repmat(string(setName), height(T), 1);

if ismember('SetID', T.Properties.VariableNames)
    T.SetName = setValues;
else
    T = addvars(T, setValues, 'Before', 1, 'NewVariableNames', 'SetID');
end
end

function summary = summarizeSet(setName, T)
SetName = string(setName);
NRows = height(T);

if ismember('CellID', T.Properties.VariableNames)
    NCells = numel(unique(T.CellID));
else
    NCells = NaN;
end

if ismember('MappingType', T.Properties.VariableNames)
    NTensionMapped = sum(T.MappingType == "TensionMapped");
    NSDMapped = sum(T.MappingType == "SDMapped");
else
    NTensionMapped = NaN;
    NSDMapped = NaN;
end

NValidTension = countFiniteColumn(T, 'Tension');
NValidSDt = countFiniteColumn(T, 'SDt');
NValidSDs = countFiniteColumn(T, 'SDs');

summary = table(SetName, NRows, NCells, NTensionMapped, NSDMapped, ...
    NValidTension, NValidSDt, NValidSDs);
end

function n = countFiniteColumn(T, columnName)
if ismember(columnName, T.Properties.VariableNames)
    n = sum(isfinite(T.(columnName)));
else
    n = NaN;
end
end

