% Define the input file and sheet name
inputFile = 'compiled_data.xlsx';
sheetName = 'tared_data';

% Read the tared data
taredData = readtable(inputFile, 'Sheet', sheetName, 'VariableNamingRule', 'preserve');

% Get column names
columnNames = taredData.Properties.VariableNames;

% Initialize results table
statsTable = table();

% Loop through the columns in pairs (rotation and torque for each dataset)
for i = 1:2:length(columnNames)
    % Extract dataset name by removing '_rotation_tared' from the column name
    datasetName = erase(columnNames{i}, '_rotation_tared');

    % Extract rotation and torque data
    rotationData = taredData{:, i};
    torqueData = taredData{:, i+1};

    % Compute statistics
    maxRotation = max(rotationData, [], 'omitnan');
    minRotation = min(rotationData, [], 'omitnan');
    maxTorque = max(torqueData, [], 'omitnan');
    minTorque = min(torqueData, [], 'omitnan');

    % Store results in a row (using cell array for text data)
    newRow = table(string(datasetName), maxRotation, minRotation, maxTorque, minTorque, ...
                   'VariableNames', {'Dataset', 'MaxRotation', 'MinRotation', 'MaxTorque', 'MinTorque'});

    % Append to results table
    statsTable = [statsTable; newRow]; %#ok<AGROW>
end

% Write the results to a new sheet in the same file
outputSheet = 'boundary';
writetable(statsTable, inputFile, 'Sheet', outputSheet);

fprintf('Statistics have been saved to "%s" in the sheet "%s".\n', inputFile, outputSheet);
