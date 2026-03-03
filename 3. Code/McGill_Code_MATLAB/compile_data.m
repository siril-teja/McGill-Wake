% Set the directory where the CSV files are located
inputDir = 'C:\Users\siril\OneDrive - McGill University\McGill Masters\Academics\TIM Research\McGill - Wakeforest project\Testing with Emma\Full Data\FE+LB\Sawbones\all_csv_files';  % Update with your folder path

% Get a list of all CSV files in the directory
csvFiles = dir(fullfile(inputDir, '*.csv'));

% Extract numeric values from filenames and sort them
fileNames = {csvFiles.name};
numValues = zeros(size(fileNames));

for k = 1:length(fileNames)
    % Extract numeric part from filename using regex
    tokens = regexp(fileNames{k}, '(\d+)', 'match'); 
    if ~isempty(tokens)
        numValues(k) = str2double(tokens{1});  % Convert first numeric token to number
    end
end

% Sort files based on extracted numeric values
[~, sortedIdx] = sort(numValues);
csvFiles = csvFiles(sortedIdx);

% Initialize an empty table to hold the concatenated raw data
combinedData = table();
taredData = table();

% Initialize variable to track the maximum number of rows
maxRows = 0;

% First pass: Determine the maximum number of rows across all files
for k = 1:length(csvFiles)
    filePath = fullfile(csvFiles(k).folder, csvFiles(k).name);
    data = readtable(filePath, 'VariableNamingRule', 'preserve');
    maxRows = max(maxRows, height(data));
end

% Loop through all the CSV files and extract columns K and L
for k = 1:length(csvFiles)
    filePath = fullfile(csvFiles(k).folder, csvFiles(k).name);
    fprintf('Processing file: %s\n', filePath);
    
    data = readtable(filePath, 'VariableNamingRule', 'preserve');

    if size(data, 2) < 12
        fprintf('Skipping file: %s (insufficient columns)\n', filePath);
        continue;
    end
    
    % Extract columns K and L (11th and 12th columns)
    extractedData = data(:, 11:12);

    % Ensure table has uniform row count by padding with NaN
    if height(extractedData) < maxRows
        numMissingRows = maxRows - height(extractedData);
        missingRows = array2table(nan(numMissingRows, width(extractedData)), 'VariableNames', extractedData.Properties.VariableNames);
        extractedData = [extractedData; missingRows];
    end

    % Extract filename (without extension)
    [~, fileName, ~] = fileparts(filePath);
    
    % Rename columns with filename included
    extractedData.Properties.VariableNames = {sprintf('%s_rotation', fileName), sprintf('%s_torque', fileName)};
    
    % Concatenate raw data
    combinedData = [combinedData, extractedData];

    % Compute tared data
    taredRotation = extractedData{:, 1} - extractedData{1, 1};
    taredTorque = extractedData{:, 2} - extractedData{1, 2};
    
    % Convert to table
    taredExtractedData = table(taredRotation, taredTorque, 'VariableNames', {sprintf('%s_rotation_tared', fileName), sprintf('%s_torque_tared', fileName)});
    
    % Concatenate tared data
    taredData = [taredData, taredExtractedData];
end

% Write data to Excel
outputFileName = 'compiled_data.xlsx';
writetable(combinedData, outputFileName, 'Sheet', 'raw_data');
writetable(taredData, outputFileName, 'Sheet', 'tared_data');

fprintf('Data written to %s with correct sorting.\n', outputFileName);

hysteresis_area;
boundary;
boundary_plot;
polynomial_fit;
stiffness;
data_3d;
