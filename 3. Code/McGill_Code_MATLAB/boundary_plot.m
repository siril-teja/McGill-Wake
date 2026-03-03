% Define the input file and sheet name
inputFile = 'compiled_data.xlsx';
boundarySheet = 'boundary';

% Read the boundary data
boundaryData = readtable(inputFile, 'Sheet', boundarySheet, 'VariableNamingRule', 'preserve');

% Extract the relevant columns: Dataset, MaxRotation, and MinRotation
datasetNames = boundaryData.Dataset;  % Dataset names (e.g., '0-180', '15-195', etc.)
maxRotationValues = boundaryData.MaxRotation;  % Max rotation values
minRotationValues = boundaryData.MinRotation;  % Min rotation values

% Initialize figure for the polar plot
figure;
ax = axes;  % Create regular axes for the polar plot

% Set the number of datasets
numDatasets = length(datasetNames);

% Initialize arrays to store the theta values (angles in degrees)
thetaValues = zeros(1, numDatasets * 2);  % Will store the angles in degrees (for both max and min rotation)
rotationValues = zeros(1, numDatasets * 2);  % Will store the corresponding rotation values

% Loop through each dataset and extract max and min rotation
for i = 1:numDatasets
    % Extract the dataset name (e.g., '0-180', '15-195', etc.)
    datasetName = datasetNames{i};
    
    % Extract the corresponding max and min rotation values for this dataset
    maxRotation = maxRotationValues(i);
    minRotation = minRotationValues(i);
    
    % Extract the angle from the dataset name (e.g., '0-180' -> 0)
    angleValue1 = str2double(regexp(datasetName, '^\d+', 'match', 'once'));  % First number for max rotation
    
    % Extract the second angle from the dataset name (e.g., '0-180' -> 180)
    angleValue2 = str2double(regexp(datasetName, '\d+$', 'match', 'once'));  % Second number for min rotation
    
    % Store the dataset angles and rotations
    thetaValues(i) = angleValue1;  % Angle value (in degrees) for max rotation
    rotationValues(i) = maxRotation;  % Max rotation value
    
    % Store the second half with absolute value of min rotation
    thetaValues(i + numDatasets) = angleValue2;  % Second angle value for min rotation
    rotationValues(i + numDatasets) = abs(minRotation);  % Absolute value of min rotation
end

% To connect the first and last points, append the first point to the end
thetaValues(end+1) = thetaValues(1);  % Add the first point to the end
rotationValues(end+1) = rotationValues(1);  % Add the corresponding rotation value to the end

% Create a polar plot with max and min rotation values
polarplot(deg2rad(thetaValues), rotationValues, '-o', 'LineWidth', 2);  % Use deg2rad for polarplot

% Customize the plot
title('Boundary Data');
thetalim([0 360]);  % Limit the theta axis from 0 to 360 degrees

% Set the tick positions at 0, 15, 30, ..., 165, 180, 195, ..., 345
thetaTicks = 0:15:360;  % Create the theta ticks from 0 to 360 in increments of 15

% Set the ticks and labels for theta axis
thetaticks(thetaTicks);  % Place the ticks
thetaticklabels(arrayfun(@(x) sprintf('%d', x), thetaTicks, 'UniformOutput', false));  % Set the labels (as string)

% Display the plot
grid on;
