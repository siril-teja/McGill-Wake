% Define the input file and sheet name
inputFile = 'compiled_data.xlsx';
sheetName = '3d_data';

% Read the data from the '3d_data' sheet
data = readtable(inputFile, 'Sheet', sheetName);

% Create a new figure
figure;

% Prepare data for 3D plotting
theta = data.Theta;  % Angle (Theta) from dataset name
rotation = data.Rotation;  % Rotation data
torque = data.Torque;  % Torque data

% Calculate stiffness as the absolute value of torque/rotation
stiffness = abs(torque ./ rotation);

% Convert theta and rotation to radians
thetaRad = deg2rad(theta);  % Convert theta from degrees to radians

% Create a meshgrid for theta and rotation
thetaGrid = linspace(min(thetaRad), max(thetaRad), 100);  % 100 points for theta
rotationGrid = linspace(min(rotation), max(rotation), 100);  % 100 points for rotation
[thetaMesh, rotationMesh] = meshgrid(thetaGrid, rotationGrid);

% Interpolate stiffness data onto the meshgrid
stiffnessInterp = griddata(thetaRad, rotation, stiffness, thetaMesh, rotationMesh, 'linear');

% Convert polar to Cartesian coordinates
[x, y] = pol2cart(thetaMesh, rotationMesh);

% Plot the 3D surface
surf(x, y, stiffnessInterp);  % Use stiffness as the z-axis

% Add labels and title
xlabel('X');
ylabel('Y');
zlabel('Stiffness');
title('3D Plot of Stiffness vs Rotation');

% Adjust view
view(3);  % Set to 3D view
shading interp;  % Interpolate shading for a smoother appearance

% Add a color bar
colorbar;
