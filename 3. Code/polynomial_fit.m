% Define the input file and sheet name
inputFile = 'compiled_data.xlsx';
sheetName = 'tared_data';

% Read the tared data while preserving column names
taredData = readtable(inputFile, 'Sheet', sheetName, 'VariableNamingRule', 'preserve');

% Get column names
columnNames = taredData.Properties.VariableNames;

% Initialize cell arrays to store dataset tables and fit details
datasetTables = {};
fitDetails = {};

% Loop through the columns in pairs (rotation and torque for each dataset)
for i = 1:2:length(columnNames)
    % Get dataset name (remove '_rotation_tared' suffix)
    datasetName = erase(columnNames{i}, '_rotation_tared');

    % Extract rotation and torque columns
    rotationData = taredData{:, i};
    torqueData = taredData{:, i+1};

    % Remove NaN values
    validIndices = ~isnan(rotationData) & ~isnan(torqueData);
    rotationData = rotationData(validIndices);
    torqueData = torqueData(validIndices);

    % Perform a third-degree polynomial fit constrained to pass through the origin
    % Create a matrix for the polynomial terms [x^3, x^2, x]
    X = [rotationData.^3, rotationData.^2, rotationData];
    
    % Solve for the polynomial coefficients (no constant term)
    coeffs = X \ torqueData;  % This performs a least squares fit
    
    % Generate evenly spaced rotation values from the minimum to the maximum
    evenRotation = linspace(min(rotationData), max(rotationData), 100);  % 100 points for sampling

    % Calculate the corresponding torque values using the fitted polynomial
    fittedTorque = coeffs(1)*evenRotation.^3 + coeffs(2)*evenRotation.^2 + coeffs(3)*evenRotation;

    % Create the output table for this dataset
    datasetTable = table(evenRotation', fittedTorque', ...
                         'VariableNames', {sprintf('%s_rotation_tared', datasetName), ...
                                           sprintf('%s_torque_tared_fitted', datasetName)});

    % Store the dataset table
    datasetTables{end+1} = datasetTable;

    % Store fit details (coefficients) and R^2
    yFit = coeffs(1)*rotationData.^3 + coeffs(2)*rotationData.^2 + coeffs(3)*rotationData;  % Compute the fitted torque values
    ssTotal = sum((torqueData - mean(torqueData)).^2);  % Total sum of squares
    ssRes = sum((torqueData - yFit).^2);  % Residual sum of squares
    rSquared = 1 - (ssRes / ssTotal);  % R^2 calculation

    % Store fit details (coefficients and R^2)
    fitDetails{end+1} = table(coeffs(1), coeffs(2), coeffs(3), rSquared, ...
                             'VariableNames', {'Coeff1', 'Coeff2', 'Coeff3', 'R_squared'}, ...
                             'RowNames', {datasetName});
end

% Concatenate all tables horizontally for the fitted data
fittedData = horzcat(datasetTables{:});

% Concatenate all fit details vertically into one table
fitDetailsTable = vertcat(fitDetails{:});

% Write the fitted results to a new sheet named 'tared_fitted'
outputSheet = 'tared_polyfit';
writetable(fittedData, inputFile, 'Sheet', outputSheet);

% Write the fit details (coefficients and R^2) to a new sheet named 'fit_details'
fitDetailsSheet = 'fit_details';
writetable(fitDetailsTable, inputFile, 'Sheet', fitDetailsSheet, 'WriteRowNames', true);

fprintf('Fitted polynomial data has been saved to "%s" in the sheet "%s".\n', inputFile, outputSheet);
fprintf('Fit coefficients and R^2 values have been saved to "%s" in the sheet "%s".\n', inputFile, fitDetailsSheet);
