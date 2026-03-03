cd('C:\Users\emmac\Documents\GitHub\McGill-Wakeforest\')
close all
%specimens_alt = {'McGill_Surrogate1', 'Sawbones','McGill_Surrogate2', 'McGill_Surrogate3'};
%specimens_alt = {'McGill_Surrogate1','McGill_Surrogate2', 'McGill_Surrogate3','Sawbones'};
% color_vals=[243 193 179;
%     128 53 14;
%     164 234 172;
%     13 53 18;
%     196 189 151;
%     148 138 84;
%     0 0 0];
% color_vals=color_vals./255;
color_vals = [255 0 0;       % Red
              255 127 0;     % Orange
              255 255 0;     % Yellow
              0 255 0;       % Green
              0 0 255;       % Blue
              75 0 130;      % Indigo
              148 0 211;     % Violet
              255 192 203;
              0 0 0;
              128 128 128];  % Pink (extra distinct color)
color_vals = color_vals ./ 255;
for q=1:nlen % for each file
    procedure_data(q).Filename
    step_deg=15;
    tol_deg=1;           
    step_rad=deg2rad(step_deg);
    tol_rad=deg2rad(tol_deg);
    theta_axes = 0:step_rad:(pi-step_rad);
    
    for b=1:length(theta_axes)
        input_angle=theta_axes(b);
        [hyst_pts]=angle_slicer_hystorder(procedure_data(q),input_angle,tol_deg);
        % Plot
        figure(b);
        set(gcf,'Position',[250 250 700 400])
        hold on;
        subplot(3,1,1)
        hold on;
        plot(hyst_pts(:,1),hyst_pts(:,2), 'Color',color_vals(q,:), 'LineWidth', 2,'DisplayName',procedure_data(q).Filename); 
        title(string(input_angle))
        subplot(3,1,2)
        hold on;
        plot(hyst_pts(:,1))
        subplot(3,1,3)
        hold on;
        plot(hyst_pts(:,2))
        
        save_folder = fullfile(filepath, 'SPM Prep');
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        %writematrix(hyst_pts, fullfile(save_folder,strcat(string(specimens_alt(q)),'_',string(rad2deg(input_angle)),'.csv')));
        writematrix(hyst_pts, fullfile(save_folder,strcat(string(procedure_data(q).Filename),'_',string(rad2deg(input_angle)),'.csv')));
        %saveas(figure(b), fullfile(save_folder,[num2str(rad2deg(input_angle)),'_Slice_Plot.png']));
        saveas(figure(b), fullfile(save_folder,strcat(string(procedure_data(q).Filename),'_',num2str(rad2deg(input_angle)),'_Slice_Plot.png')));
    end
end
