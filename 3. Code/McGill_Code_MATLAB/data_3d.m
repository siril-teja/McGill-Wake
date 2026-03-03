% Define the input file and sheet names
inputFile = 'compiled_data.xlsx';
taredSheet = 'tared_polyfit';

% Read the tared_polyfit data
taredData = readtable(inputFile, 'Sheet', taredSheet, 'VariableNamingRule', 'preserve');

% Initialize an empty table to store the new data with (theta, rotation, torque)
thetaRotationTorque = table();

% Extract the column names from the tared sheet
columnNames = taredData.Properties.VariableNames;

% Loop through each pair of rotation and torque columns
for i = 1:2:length(columnNames)
    % Extract the rotation and torque column names
    rotationCol = columnNames{i};
    torqueCol = columnNames{i+1};
    
    % Extract the corresponding rotation and torque values
    rotationData = taredData.(rotationCol);
    torqueData = taredData.(torqueCol);
    
    % Extract the dataset name from the rotation column (e.g., '0-180_rotation_tared' -> '0-180')
    datasetName = rotationCol(1:strfind(rotationCol, '_rotation')-1);  % Extract part before '_rotation'
    
    % Extract the theta value from the dataset name (e.g., '0-180' -> 0)
    thetaParts = strsplit(datasetName, '-');  % Split based on '-'
    thetaValue = str2double(thetaParts{1});  % Get the first number
    
    % Create a temporary table for this dataset with the (theta, rotation, torque) columns
    tempTable = table(repmat(thetaValue, height(rotationData), 1), rotationData, torqueData, ...
        'VariableNames', {'Theta', 'Rotation', 'Torque'});
    
    % Append the temporary table to the main table
    thetaRotationTorque = [thetaRotationTorque; tempTable];
end

% Write the new table to a new sheet called '3d_data'
writetable(thetaRotationTorque, inputFile, 'Sheet', '3d_data');

disp('3D Data written to the "3d_data" sheet.');
