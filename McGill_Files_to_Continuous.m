%clear
clearvars -except WF_style_data
close all
clc
% Define base path
pre_filename = 'C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\McGill-Wakeforest Testing';

% Define folders (as cell array of character vectors)
folders = {'0-180', '105-285', '120-300', '135-315', '15-195', ...
           '150-330', '165-345', '30-210', '45-225', '60-240', ...
           '75-255', '90-270'};

% Define Ray values (as strings or convert to numbers if needed)
ray_vals = {'0','180','105','285','120','300','135','315','15','195', ...
            '150','330','165','345','30','210','45','225','60','240','75','255','90','270'};

% Initialize output variables
folder_theta_vals = {}; % Cell array to hold {folder_name, start_theta, end_theta}
theta_options = [];     % Array of theta values

% Loop through each folder and extract theta values
for i = 1:length(folders)
    folder = folders{i};
    parts = strsplit(folder, '-');
    start_theta = str2double(parts{1});
    end_theta = str2double(parts{2});
    
    folder_theta_vals{i,1} = folder;
    folder_theta_vals{i,2} = start_theta;
    folder_theta_vals{i,3} = end_theta;

    theta_options = [theta_options, start_theta, end_theta]; %#ok<AGROW>
end

% Define specimen directories
specimen_dirs = {'McGill Spec 1', 'McGill Spec 2', 'McGill Spec 3', 'Sawbones'};
specimen_dirs_ns = {'McGill_Spec_1', 'McGill_Spec_2', 'McGill_Spec_3', 'Sawbones'};
specimen_dirs_match = {'McGill_Surrogate1', 'McGill_Surrogate2', 'McGill_Surrogate3', 'Sawbones'};
specimen_data_MG = struct(); %containers.Map;
MG_data_summary = struct(); %containers.Map();
spec_hysteresis=struct();

for s = 1:length(specimen_dirs)
    specimen = specimen_dirs{s};
    specimen_ns = specimen_dirs_ns{s}
    all_data = [];
    MG_data_summary.(specimen_ns) = [];
    hysteresis_areas={};
    
    for f = 1:length(folders)
        folder = folders{f};
        file_path = fullfile(pre_filename, specimen, folder, folder, 'Test1');
        file_path_w_file = fullfile(file_path, 'Test1.Stop.csv');

        if isfile(file_path_w_file)
            % Try to read the CSV with default encoding
            try
                df = readtable(file_path_w_file);
            catch
                warning(['Could not read file: ', file_path_w_file]);
                continue;
            end

            % Extract and adjust data
            try
                extracted_data = df(:, {'TotalTime_s_', ...
                    'Rotation_Rotary_Rotation__deg_', ...
                    'Torque_Rotary_Torque__N_m_'});
                extracted_data.Properties.VariableNames = {'Time', 'Rotation', 'Torque'};
            catch
                warning(['Columns missing in file: ', file_path_w_file]);
                continue;
            end

            % Zero the rotation
            extracted_data.Rotation = extracted_data.Rotation - extracted_data.Rotation(1);
            if s==3
                extracted_data.Rotation = -extracted_data.Rotation;
            end
            extracted_data.Folder = repmat({folder}, height(extracted_data), 1);

            % Define theta based on rotation
            extracted_data.Theta(extracted_data.Rotation >= 0) = folder_theta_vals{f,2};
            extracted_data.Theta(extracted_data.Rotation < 0) = folder_theta_vals{f,3};

            % Define test torque
            TT = abs(extracted_data.Torque);
            % extracted_data.TestTorque = -TT;
            idx1 = (extracted_data.Theta >= 0) & (extracted_data.Theta <= 90);
            idx2 = (extracted_data.Theta >= 180) & (extracted_data.Theta <= 270);
            extracted_data.TestTorque(idx1 | idx2) = TT(idx1 | idx2);

            % Compute derivative
            extracted_data.DR = [diff(extracted_data.TestTorque); 0];

            % Append data
            all_data = [all_data; extracted_data];

            % Summary torque values
            max_val = max(extracted_data.TestTorque(extracted_data.Theta == folder_theta_vals{f,2}));
            min_val = min(extracted_data.TestTorque(extracted_data.Theta == folder_theta_vals{f,3}));
            MG_data_summary.(specimen_ns) = [MG_data_summary.(specimen_ns); extracted_data];
            hysteresis_areas{f,1}=folders{f};
            hysteresis_areas{f,2}= polyarea(extracted_data.Torque, extracted_data.Rotation);
            % Save figure
            fig = figure('Visible', 'off');
            scatter(extracted_data.Torque, extracted_data.Rotation, '.');
            xlabel('Torque (Nm)');
            ylabel('Rotation (deg)');
            title(['Torque vs Displacement Curve for ', specimen, ' ', folder]);
            saveas(fig, fullfile('C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Processing Files\Figures', ...
                [specimen, '_', folder, '.png']));
            close(fig);
        end
    end
    [xt,yt]=pol2cart(deg2rad(all_data.Theta),abs(all_data.Rotation)); %+deg2rad(90)?
    MG_data_summary.(specimen_ns).Displacements=[xt yt];
   
    compiled=figure;
    plot(xt,yt)
    title(['Data for Specimen ',specimen])
    xlabel('Lateral Bending (deg)')
    ylabel('Flexion Extension (deg)')
    saveas(compiled, fullfile('C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Processing Files\Figures', ...
                [specimen, '_Compiled', '.png']));

    % Save combined data to CSV
    specimen_data_MG.(specimen_ns) = all_data;
    spec_hysteresis.(specimen_ns)=hysteresis_areas;
    writetable(all_data, [specimen_ns, '_data.csv']);
    fprintf('Saved data for %s to %s_data.csv\n', specimen, specimen);
end
%%
nlen = length(specimen_dirs);
segment = [11 4];
% Establish a struct for storing data
procedure_data = struct('Filename',{},'Filetag',{},'Displacements',{},'Polar',{},'Loads',{},'Control',{},'Stiffness',{},'Time',{});

cd('C:\Users\emmac\Documents\GitHub\PhD-Multiplanar-Code') % Navigate to where MATLAB function files are stored
peak_stiffnesses=struct();
for i=1:nlen % iterate through all test files
    specimen_dirs_ns{i}
    procedure_data(i).Filename=specimen_dirs_ns{i};
    procedure_data(i).Filetag=specimen_dirs_match{i};
    peak_stiffnesses(i).Filename=specimen_dirs_ns{i};
    % Importing the data from the test file & storing it
    procedure_data(i).Displacements=MG_data_summary.(specimen_dirs_ns{i}).Displacements;
    Disp_theta=MG_data_summary.(specimen_dirs_ns{i}).Theta;
    Disp_dtheta=[diff(Disp_theta);0];
    Disp_rho=abs(MG_data_summary.(specimen_dirs_ns{i}).Rotation);
    Disp_drho=[diff(Disp_rho);0];
    procedure_data(i).Polar=[Disp_theta Disp_rho Disp_dtheta Disp_drho];
    procedure_data(i).ResLoad=abs(MG_data_summary.(specimen_dirs_ns{i}).Torque);
    procedure_data(i).Time=MG_data_summary.(specimen_dirs_ns{i}).Time;

    % Data fitting
    % whole data first
    [whole_load_plot,whole_stiffness_plot,whole_gradient_plot,inside_x_mesh,inside_y_mesh,inside_z_mesh,boundary_x,boundary_y,stiffness,delta_stiffness]=plot_cropped_boundary_McGill(procedure_data(i).Filename,procedure_data(i),'whole',segment);
    procedure_data(i).InsideVals=[inside_x_mesh,inside_y_mesh,inside_z_mesh];
    procedure_data(i).Stiffness=stiffness;
    peak_stiffnesses(i).MaxWhole=max(stiffness);
    procedure_data(i).DeltaStiffness=delta_stiffness;
    procedure_data(i).Boundary=[boundary_x,boundary_y];
    pgon_whole=polyshape(boundary_x, boundary_y);
    procedure_data(i).Centroid=centroid(pgon_whole);
    procedure_data(i).Area=polyarea(boundary_x,boundary_y);
    % Get inward & outward data (can change or add CW & CCW if desired)
    [in_load_plot,in_stiffness_plot,in_gradient_plot,inside_x_mesh,inside_y_mesh,inside_z_mesh,boundary_x,boundary_y,stiffness,delta_stiffness]=plot_cropped_boundary_McGill(procedure_data(i).Filename,procedure_data(i),"in",segment);
    procedure_data(i).In_Mesh=[inside_x_mesh,inside_y_mesh,inside_z_mesh];
    procedure_data(i).In_Stiffness=stiffness;
    peak_stiffnesses(i).MaxIn=max(stiffness) 
    procedure_data(i).InDeltaStiffness=delta_stiffness;
    procedure_data(i).In_Boundary=[boundary_x,boundary_y];
    [out_load_plot,out_stiffness_plot,out_gradient_plot,inside_x_mesh,inside_y_mesh,inside_z_mesh,boundary_x,boundary_y,stiffness,delta_stiffness]=plot_cropped_boundary_McGill(procedure_data(i).Filename,procedure_data(i),"out",segment);
    procedure_data(i).Out_Mesh=[inside_x_mesh,inside_y_mesh,inside_z_mesh];
    procedure_data(i).Out_Stiffness=stiffness;
    peak_stiffnesses(i).MaxOut=max(stiffness) 
    procedure_data(i).OutDeltaStiffness=delta_stiffness;
    procedure_data(i).Out_Boundary=[boundary_x,boundary_y];

    % Save plots
    save_folder = fullfile(pre_filename, '\Figures\', procedure_data(i).Filename);
    if ~exist(save_folder, 'dir')
        mkdir(save_folder);
    end
    saveas(whole_load_plot, fullfile(save_folder,'Whole_Load.png'));
    saveas(whole_stiffness_plot, fullfile(save_folder,'Whole_Stiffness.png'));
    saveas(whole_gradient_plot, fullfile(save_folder,'Whole_Gradient.png'));
    saveas(in_load_plot, fullfile(save_folder,'In_Load.png'));
    saveas(in_stiffness_plot, fullfile(save_folder,'In_Stiffness.png'));
    saveas(in_gradient_plot, fullfile(save_folder,'In_Gradient.png'));
    saveas(out_load_plot, fullfile(save_folder,'Out_Load.png'));
    saveas(out_stiffness_plot, fullfile(save_folder,'Out_Stiffness.png'));
    saveas(out_gradient_plot, fullfile(save_folder,'Out_Gradient.png'));
end
MG_style_data=procedure_data;
stiffpeaks=struct2table(peak_stiffnesses)
writetable(stiffpeaks, [pre_filename,'stiffness_peaks.csv']);
