%% In-Out Slice Focus
close all;
nfit=200;
NZ_thresh=0.5;
EZ_thresh=NZ_thresh;
combined_length=length(MG_style_data)+length(WF_style_data);
specimens = {'McGill_Surrogate1', 'McGill_Surrogate2', 'McGill_Surrogate3', 'Sawbones'};
%step_deg = input("Steps? (enter number in degrees)");           % downsampling angle spacing (e.g., 15 degrees)
step_deg=15;
tol_deg=5;           % tolerance around each axis in degrees
step_rad=deg2rad(step_deg);
tol_rad=deg2rad(tol_deg);
theta_axes = 0:step_rad:(pi-step_rad);
index_data=struct();
spec_data=struct();
for j=1:length(specimens) % for each file
    spec_data(j).Specimen=specimens(j)
    hysteresis_areas={};
    for k=1:length(specimens)
        if find(MG_style_data(k).Filetag == string(specimens(j)))
            MG=MG_style_data(k);
        end
        if find(WF_style_data(k).Filetag == string(specimens(j)))
            WF=WF_style_data(k);
        end
    end
    
    for b=1:length(theta_axes)
        input_angle=theta_axes(b);
        index_data(b).Angle = input_angle; % may also be able to use theta_deg from angle_slicer function
        
        % Inward
        [MG_points_in,MG_results_in]=angle_slicer_s(MG.In_Mesh(:,1),MG.In_Mesh(:,2),MG.In_Mesh(:,3),MG.In_Stiffness(:),input_angle,tol_deg); % input_angle is radians, tolerance is degrees
        index_data(b).MG_In_Points=MG_points_in;
        index_data(b).MG_In_Results=MG_results_in;
        MG_r_fit_in = linspace(min(MG_points_in(:,1)), max(MG_points_in(:,1)), nfit); % Theta
        MG_z_fit_plot_in = polyval(MG_results_in(2:5), MG_r_fit_in); % Moment
        MG_dM_dTheta_in = abs(polyval(MG_results_in(7:10), MG_r_fit_in)); 

        [WF_points_in,WF_results_in]=angle_slicer_s(WF.In_Mesh(:,1),WF.In_Mesh(:,2),WF.In_Mesh(:,3),WF.In_Stiffness(:),input_angle,tol_deg); % input_angle is radians, tolerance is degrees
        index_data(b).WF_In_Points=WF_points_in;
        index_data(b).WF_In_Results=WF_results_in;
        WF_r_fit_in = linspace(min(WF_points_in(:,1)), max(WF_points_in(:,1)), nfit); % Theta
        WF_z_fit_plot_in = polyval(WF_results_in(2:5), WF_r_fit_in); % Moment
        WF_dM_dTheta_in = abs(polyval(WF_results_in(7:10), WF_r_fit_in)); 

        current_plot=figure;
        plot(MG_r_fit_in,MG_z_fit_plot_in,'Color',[248 32 33]./255,'LineStyle','-','LineWidth', 2,'DisplayName','McGill Inward Data'); 
        hold on;       
        plot(WF_r_fit_in,WF_z_fit_plot_in,'Color',[140 109 44]./255,'LineStyle','-','LineWidth', 2,'DisplayName','Wake Inward Data'); 
        
        % Outward
        [MG_points_out,MG_results_out]=angle_slicer_s(MG.Out_Mesh(:,1),MG.Out_Mesh(:,2),MG.Out_Mesh(:,3),MG.Out_Stiffness(:),input_angle,tol_deg); % input_angle is degrees, tolerance is degrees
        index_data(b).MG_Out_Points=MG_points_out;
        index_data(b).MG_Out_Results=MG_results_out;
        MG_r_fit_out = linspace(min(MG_points_out(:,1)), max(MG_points_out(:,1)), nfit); % Theta
        MG_z_fit_plot_out = polyval(MG_results_out(2:5), MG_r_fit_out); % Moment
        MG_dM_dTheta_out = abs(polyval(MG_results_out(7:10), MG_r_fit_out));

        [WF_points_out,WF_results_out]=angle_slicer_s(WF.Out_Mesh(:,1),WF.Out_Mesh(:,2),WF.Out_Mesh(:,3),WF.Out_Stiffness(:),input_angle,tol_deg); % input_angle is degrees, tolerance is degrees
        index_data(b).WF_Out_Points=WF_points_out;
        index_data(b).WF_Out_Results=WF_results_out;
        WF_r_fit_out = linspace(min(WF_points_out(:,1)), max(WF_points_out(:,1)), nfit); % Theta
        WF_z_fit_plot_out = polyval(WF_results_out(2:5), WF_r_fit_out); % Moment
        WF_dM_dTheta_out = abs(polyval(WF_results_out(7:10), WF_r_fit_out));

        plot(MG_r_fit_out,MG_z_fit_plot_out,'Color',[248 32 33]./255,'LineStyle','--','LineWidth', 2,'DisplayName','McGill Outward Data');            
        plot(WF_r_fit_out,WF_z_fit_plot_out,'Color',[140 109 44]./255,'LineStyle','--','LineWidth', 2,'DisplayName','Wake Outward Data');            
        xlabel('Rotation (°)');
        ylabel('Moment (Nm)');
        ylim([-segment(1),segment(1)])
        legend show
        legend('Location','northwest')
        title([string(specimens(j)),' Inward & Outward Data for ',num2str(rad2deg(input_angle))],'Interpreter','none');
        grid on;

        hysteresis_areas{b,1}=input_angle;
        hysteresis_areas{b,2}=abs(trapz(MG_points_in(:,1),MG_points_in(:,2))-trapz(MG_points_out(:,1),MG_points_out(:,2)));
        hysteresis_areas{b,3}=abs(trapz(WF_points_in(:,1),WF_points_in(:,2))-trapz(WF_points_out(:,1),WF_points_out(:,2)));
  
        save_folder = fullfile('C:\Users\emmac\Documents\SBES\Brown Lab\McGill\', 'Figures', string(specimens(j)));
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        saveas(current_plot, fullfile(save_folder,[num2str(rad2deg(input_angle)),'_Slice_Plot.png']));
    end
    spec_data(j).IndexData=index_data;
    spec_data(j).Hysteresis=hysteresis_areas;
end

figure; 
bar(cell2mat(spec_data(1).Hysteresis(:,1)),[cell2mat(spec_data(1).Hysteresis(:,2)) cell2mat(spec_data(1).Hysteresis(:,3))])

%% In-Out Slice Focus - the polar way
close all;
nfit=200;
npoly=3;
combined_length=length(MG_style_data)+length(WF_style_data);
specimens = {'McGill_Surrogate1', 'McGill_Surrogate2', 'McGill_Surrogate3', 'Sawbones'};
%step_deg = input("Steps? (enter number in degrees)");           % downsampling angle spacing (e.g., 15 degrees)
step_deg=15;
tol_deg=5;           % tolerance around each axis in degrees
step_rad=deg2rad(step_deg);
tol_rad=deg2rad(tol_deg);
theta_axes = 0:step_rad:(pi-step_rad);
index_data=struct();
spec_data=struct();
for j=1:length(specimens)
    spec_data(j).Specimen=specimens(j)
    hysteresis_areas={};
    for k=1:length(specimens)
        if find(MG_style_data(k).Filetag == string(specimens(j)))
            MG=MG_style_data(k);
        end
        if find(WF_style_data(k).Filetag == string(specimens(j)))
            WF=WF_style_data(k);
        end
    end
    
    for b=1:length(theta_axes)
        input_angle=theta_axes(b);
        input_angle_deg=rad2deg(input_angle);
        index_data(b).Angle = input_angle; % may also be able to use theta_deg from angle_slicer function
        
        % McGill - Polar is in degrees, 0-360
        % "Loading" -> theta < 180 & dR out, theta > 180 & dR in
        % [Disp_theta Disp_rho Disp_dtheta Disp_drho];
        % Lind_p=MG.Polar(:,1)<=input_angle_deg+tol_deg & MG.Polar(:,1)>=input_angle_deg-tol_deg;
        Lind_p_pr=MG.Polar(:,1)<=input_angle_deg+tol_deg & MG.Polar(:,1)>=input_angle_deg-tol_deg & MG.Polar(:,4)>0;
        %Lind_n=MG.Polar(:,1)<=input_angle_deg+180+tol_deg & MG.Polar(:,1)>=input_angle_deg+180-tol_deg;
        Lind_n_nr=MG.Polar(:,1)<=input_angle_deg+180+tol_deg & MG.Polar(:,1)>=input_angle_deg+180-tol_deg & MG.Polar(:,4)<0;
        index_data(b).MG_L_Points=[MG.Polar(Lind_p_pr,2) MG.ResLoad(Lind_p_pr); -MG.Polar(Lind_n_nr,2) -MG.ResLoad(Lind_n_nr);]
        [MG_pL,MG_SL] = polyfit(index_data(b).MG_L_Points(:,1),index_data(b).MG_L_Points(:,2),npoly);
        [MG_Ly_fit,MG_Ldelta] = polyval(MG_pL,index_data(b).MG_L_Points(:,1),MG_SL);
        
        % "Unloading" -> theta < 180 & dR in, theta > 180 & dR out
        % [Disp_theta Disp_rho Disp_dtheta Disp_drho];
        % Uind_p=MG.Polar(:,1)<=input_angle_deg+tol_deg & MG.Polar(:,1)>=input_angle_deg-tol_deg;
        Uind_p_pr=MG.Polar(:,1)<=input_angle_deg+tol_deg & MG.Polar(:,1)>=input_angle_deg-tol_deg & MG.Polar(:,4)<0;
        % Uind_n=MG.Polar(:,1)<=input_angle_deg+180+tol_deg & MG.Polar(:,1)>=input_angle_deg+180-tol_deg;
        Uind_n_nr=MG.Polar(:,1)<=input_angle_deg+180+tol_deg & MG.Polar(:,1)>=input_angle_deg+180-tol_deg & MG.Polar(:,4)>0;
        index_data(b).MG_U_Points=[MG.Polar(Uind_p_pr,2) MG.ResLoad(Uind_p_pr); -MG.Polar(Uind_n_nr,2) -MG.ResLoad(Uind_n_nr);]
        [MG_pU,MG_SU] = polyfit(index_data(b).MG_U_Points(:,1),index_data(b).MG_U_Points(:,2),npoly);
        [MG_Uy_fit,MG_Udelta] = polyval(MG_pU,index_data(b).MG_U_Points(:,1),MG_SU);

        % Wake Forest - Polar is in radians, 0-180,0--180
        % "Loading" -> theta < 180 & dR out, theta > 180 & dR in
        WLind_p_pr=WF.Polar(:,1)<=input_angle+tol_rad & WF.Polar(:,1)>=input_angle-tol_rad & WF.Polar(:,4)>0;
        WLind_n_nr=WF.Polar(:,1)>=-input_angle-tol_rad & WF.Polar(:,1)<=-input_angle+tol_rad & WF.Polar(:,4)<0;
        index_data(b).WF_L_Points=[WF.Polar(WLind_p_pr,2) WF.ResLoad(WLind_p_pr); -WF.Polar(WLind_n_nr,2) -WF.ResLoad(WLind_n_nr);]
        [WF_pL,WF_SL] = polyfit(index_data(b).WF_L_Points(:,1),index_data(b).WF_L_Points(:,2),npoly);
        [WF_Ly_fit,WF_Ldelta] = polyval(WF_pL,index_data(b).WF_L_Points(:,1),WF_SL);
        
        % "Unloading" -> theta < 180 & dR in, theta > 180 & dR out
        WUind_p_pr=WF.Polar(:,1)<=input_angle+tol_rad & WF.Polar(:,1)>=input_angle-tol_rad & WF.Polar(:,4)<0;
        WUind_n_nr=WF.Polar(:,1)>=-input_angle-tol_rad & WF.Polar(:,1)<=-input_angle+tol_rad & WF.Polar(:,4)>0;
        index_data(b).WF_U_Points=[WF.Polar(WUind_p_pr,2) WF.ResLoad(WUind_p_pr); -WF.Polar(WUind_n_nr,2) -WF.ResLoad(WUind_n_nr);]
        [WF_pU,WF_SU] = polyfit(index_data(b).WF_U_Points(:,1),index_data(b).WF_U_Points(:,2),npoly);
        [WF_Uy_fit,WF_Udelta] = polyval(WF_pU,index_data(b).WF_U_Points(:,1),WF_SU);

        current_plot=figure;
        % plot(index_data(b).MG_L_Points(:,1),MG_Ly_fit,'Color',[248 32 33]./255,'LineStyle','-','LineWidth', 2,'DisplayName','McGill Inward Data'); 
        % hold on;       
        % plot(index_data(b).WF_L_Points(:,1),WF_Ly_fit,'Color',[140 109 44]./255,'LineStyle','-','LineWidth', 2,'DisplayName','Wake Inward Data'); 
        % plot(index_data(b).MG_U_Points(:,1),MG_Uy_fit,'Color',[248 32 33]./255,'LineStyle','--','LineWidth', 2,'DisplayName','McGill Outward Data');            
        % plot(index_data(b).WF_U_Points(:,1),WF_Uy_fit,'Color',[140 109 44]./255,'LineStyle','--','LineWidth', 2,'DisplayName','Wake Outward Data');            
        % 
        s=20;
        CM=[248 32 33]./255;
        CW=[140 109 44]./255;
        scatter(index_data(b).MG_L_Points(:,1),index_data(b).MG_L_Points(:,2),s,CM,'filled'); 
        hold on;
        scatter(index_data(b).MG_U_Points(:,1),index_data(b).MG_U_Points(:,2),s,CM,'filled'); 
        scatter(index_data(b).WF_L_Points(:,1),index_data(b).WF_L_Points(:,2),s,CW,'filled'); 
        scatter(index_data(b).WF_U_Points(:,1),index_data(b).WF_U_Points(:,2),s,CW,'filled'); 
        xlabel('Rotation (°)');
        ylabel('Moment (Nm)');
        ylim([-segment(1),segment(1)])
%        legend show
%        legend('Location','northwest')
        title([string(specimens(j)),' Inward & Outward Data for ',num2str(rad2deg(input_angle))],'Interpreter','none');
        grid on;

        hysteresis_areas{b,1}=rad2deg(input_angle);
        hysteresis_areas{b,2}=abs(trapz(index_data(b).MG_L_Points(:,1),index_data(b).MG_L_Points(:,2))-trapz(index_data(b).MG_U_Points(:,1),index_data(b).MG_U_Points(:,2)));
        hysteresis_areas{b,3}=abs(trapz(index_data(b).WF_L_Points(:,1),index_data(b).WF_L_Points(:,2))-trapz(index_data(b).WF_U_Points(:,1),index_data(b).WF_U_Points(:,2)));
  
        save_folder = fullfile('C:\Users\emmac\Documents\SBES\Brown Lab\McGill\', 'Figures from Polar', string(specimens(j)));
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        saveas(current_plot, fullfile(save_folder,[num2str(rad2deg(input_angle)),'_Slice_Plot.png']));
    end
    spec_data(j).IndexData=index_data;
    spec_data(j).Hysteresis=hysteresis_areas;
    hyst=figure; 
    h = bar(cell2mat(spec_data(j).Hysteresis(:,1)), [cell2mat(spec_data(j).Hysteresis(:,2)) cell2mat(spec_data(j).Hysteresis(:,3))]);
    h(1).FaceColor = CM; h(2).FaceColor = CW;
    title(['Hysteresis Area by Slice Angle for Specimen ',string(spec_data(j).Specimen)],'Interpreter','none')
    xlabel('Slice Angle')
    ylabel('Area (Nm/deg)')
    saveas(hyst, fullfile(save_folder,'Hyst_Areas.png'));

end

