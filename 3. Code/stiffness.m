% Define the input file and sheet name
inputFile = 'compiled_data.xlsx';
fittedSheetName = 'tared_polyfit';

% Read the fitted data from the tared_fitted sheet
fittedData = readtable(inputFile, 'Sheet', fittedSheetName, 'VariableNamingRule', 'preserve');

% Get column names for the fitted data (rotation and torque for each dataset)
columnNames = fittedData.Properties.VariableNames;

% Initialize an empty cell array to store the stiffness dataset tables
stiffnessTables = {};

% Loop through the columns in pairs (rotation and fitted torque for each dataset)
for i = 1:2:length(columnNames)
    % Get dataset name (remove '_rotation_tared' suffix)
    datasetName = erase(columnNames{i}, '_rotation_tared');

    % Extract rotation and fitted torque columns
    rotationData = fittedData{:, i};
    torqueData = fittedData{:, i+1};

    % Calculate stiffness (torque / rotation)
    stiffnessData = torqueData ./ rotationData;

    % Create the output table for this dataset
    stiffnessTable = table(rotationData, stiffnessData, ...
                           'VariableNames', {sprintf('%s_rotation_tared', datasetName), ...
                                             sprintf('%s_stiffness', datasetName)});

    % Store the stiffness dataset table
    stiffnessTables{end+1} = stiffnessTable;
end

% Concatenate all tables horizontally for the stiffness data
stiffnessData = horzcat(stiffnessTables{:});

% Write the stiffness data to a new sheet named 'stiffness'
outputSheet = 'stiffness';
writetable(stiffnessData, inputFile, 'Sheet', outputSheet);

fprintf('Stiffness data has been saved to "%s" in the sheet "%s".\n', inputFile, outputSheet);
