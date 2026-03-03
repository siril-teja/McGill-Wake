% Load the tared data sheet
taredData = readtable('compiled_data.xlsx', 'Sheet', 'tared_data', 'VariableNamingRule', 'preserve');

% Extract variable names
varNames = taredData.Properties.VariableNames;

% Initialize an empty cell array to store hysteresis results
hysteresisResults = cell(length(varNames)/2, 2);
rowIndex = 1;  % Row counter for results

% Loop through columns in pairs (each dataset has a rotation and torque column)
for k = 1:2:length(varNames)  % Step by 2 to handle rotation & torque pairs
    rotationCol = varNames{k};      % Rotation column name
    torqueCol = varNames{k+1};      % Torque column name
    
    % Extract data for the current dataset
    rotationData = taredData{:, rotationCol};
    torqueData = taredData{:, torqueCol};
    
    % Remove NaN values (if any) before integration
    validIdx = ~isnan(rotationData) & ~isnan(torqueData);
    rotationData = rotationData(validIdx);
    torqueData = torqueData(validIdx);
    
    % Compute hysteresis area using the trapezoidal rule
    hysteresisArea = abs(trapz(rotationData, torqueData));
    
    % Store dataset name and hysteresis area
    datasetName = erase(rotationCol, '_rotation_tared'); % Extract dataset name
    hysteresisResults{rowIndex, 1} = datasetName;
    hysteresisResults{rowIndex, 2} = hysteresisArea;
    
    rowIndex = rowIndex + 1;  % Increment row index
end

% Convert the result into a table
hysteresisTable = cell2table(hysteresisResults, 'VariableNames', {'Dataset', 'Hysteresis_Area'});

% Write hysteresis results to a new sheet in the Excel file
writetable(hysteresisTable, 'compiled_data.xlsx', 'Sheet', 'hysteresis_area');

fprintf('Hysteresis areas have been calculated and saved in "hysteresis_area" sheet.\n');
