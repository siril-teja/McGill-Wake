function [load_plot,stiffness_plot,gradient_plot,inside_x_mesh,inside_y_mesh,inside_z_mesh,boundary_x,boundary_y,inside_zs_mesh,inside_zsd_mesh]=plot_cropped_boundary_McGill(filename,Data,criteria,seglim) % could add other optional features for figures/steps
    % Get relevant indices, if not whole struct
    switch criteria
        case "whole"
            idx = true(size(Data.Polar,1),1);
        case "out"
            idx = Data.Polar(:,4) > 0;
        case "in"
            idx = Data.Polar(:,4) <= 0;
        case "CW" % check these
            idx = Data.Polar(:,3) <= 0;
        case "CCW" % check these
            idx = Data.Polar(:,3) > 0;
    end
    subset = [Data.Displacements(idx,1) Data.Displacements(idx,2) Data.ResLoad(idx)];
    
    % Identify the boundary
    k = convhull(gather(gpuArray(subset(:,1))), gather(gpuArray(subset(:,2))));
    boundary_x = subset(k,1);
    boundary_y = subset(k,2);
    [in, ~] = inpolygon(subset(:,1), subset(:,2), boundary_x, boundary_y);
    inside_x = subset(in,1);
    inside_y = subset(in,2);
    inside_z = subset(in,3);

    % figure;
    % scatter(inside_x,inside_y)
    % hold on
    % plot(boundary_x,boundary_y)
    % hold off
    
    % Gridfit to the points inside the boundary
    step=0.2; %recommend 0.25
    gx=min(inside_x):step:max(inside_x);
    gy=min(inside_y):step:max(inside_y);
    g=gridfit(subset(:,1), subset(:,2), subset(:,3),gx,gy);
       
    % Crop the data within the gridfit 
    [inside_x_mesh,inside_y_mesh,inside_z_mesh]=cropped_gridfit(inside_x,inside_y,gx,gy,g);
    
    % Plotting the cropped gridfit
    load_plot = figure;
    surfir(inside_x_mesh,inside_y_mesh,inside_z_mesh,0.1);
    colormap(slanCM('YlOrBr'));
    title([filename," ",criteria],'Interpreter', 'none')
%    xlabel('Lateral Bending (deg)')
    xlabel({'Lateral Bending (deg)', '\bf <- Left LB -, Right LB + ->'}, 'FontSize', 12)
    %xlim([-15 15])
%    ylabel('Flexion Extension Bending (deg)')
    ylabel({'Flexion Extension Bending (deg)', '\bf <- Flex -, Ext + ->'}, 'FontSize', 12)
    %ylim([-20 15])
    zlabel('Resultant Load (Nm)')
    zlim([0 seglim(1)])
    cb = colorbar(); 
    caxis([0 seglim(1)]); %to standardize colorbar
    ylabel(cb,'Resultant Load (Nm)','FontSize',14,'Rotation',270)
    view(0,90)

    % Calculate stiffnesses through gradient
    [dzdx, dzdy] = gradient(g, gx',gy);
    % As criterion to see when boundary stops changing?
    %max(abs(diff(dzdx)))
    grad_mag = sqrt(dzdx.^2 + dzdy.^2); % Compute gradient magnitude
    grad_diff = [sqrt(diff(dzdx).^2 + diff(dzdy).^2); zeros(size(dzdx,2),1)'];
    
    % figure;
    % imagesc(gx,gy, grad_mag);
    % colorbar;
    % title('Gradient Magnitude Heatmap');
    % xlabel('X'); ylabel('Y');
    % axis xy; % Keep correct orientation

    % figure;
    % imagesc(gx,gy, grad_diff);
    % colorbar;
    % title('Gradient Difference Heatmap');
    % xlabel('X'); ylabel('Y');
    % axis xy; % Keep correct orientation


%    g_grad=gridfit(Data.Control(idx,4), Data.Control(idx,6), grad_mag(idx),gx,gy);
    % Stiffness crop fit
    [inside_xs_mesh,inside_ys_mesh,inside_zs_mesh]=cropped_gridfit(inside_x,inside_y,gx,gy,grad_mag);    
    
    % Plotting the cropped gridfit
    stiffness_plot = figure;
    surfir(inside_xs_mesh,inside_ys_mesh,inside_zs_mesh,0.1);
    colormap(slanCM('YlOrBr'));
    title([filename," ",criteria],'Interpreter', 'none')
%    xlabel('Lateral Bending (deg)')
    xlabel({'Lateral Bending (deg)', '\bf <- Left LB -, Right LB + ->'}, 'FontSize', 12)
    %xlim([-15 15])
%    ylabel('Flexion Extension Bending (deg)')
    ylabel({'Flexion Extension Bending (deg)', '\bf <- Flex -, Ext + ->'}, 'FontSize', 12)
    %ylim([-20 15])
    zlabel('Stiffness (Nm/deg)')
    zlim([0 seglim(2)])
    cb = colorbar(); 
    caxis([0 seglim(2)]); %to standardize colorbar
    ylabel(cb,'Stiffness (Nm/deg)','FontSize',14,'Rotation',270)
    view(0,90)

    % Derivative stiffness crop fit
    [inside_xsd_mesh,inside_ysd_mesh,inside_zsd_mesh]=cropped_gridfit(inside_x,inside_y,gx,gy,grad_diff);

    % Plotting the cropped gridfit
    gradient_plot = figure;
    surfir(inside_xsd_mesh,inside_ysd_mesh,inside_zsd_mesh,0.1);
    colormap(slanCM('YlOrBr'));
    title([filename," ",criteria],'Interpreter', 'none')
%    xlabel('Lateral Bending (deg)')
    xlabel({'Lateral Bending (deg)', '\bf <- Left LB -, Right LB + ->'}, 'FontSize', 12)
    %xlim([-15 15])
%    ylabel('Flexion Extension Bending (deg)')
    ylabel({'Flexion Extension Bending (deg)', '\bf <- Flex -, Ext + ->'}, 'FontSize', 12)
    %ylim([-20 15])
    zlabel('Change in Stiffness \Delta (Nm/deg)')
    %zlim([0 0.02])
    cb = colorbar(); 
    %caxis([0 0.02]); %to standardize colorbar
    ylabel(cb,'Change in Stiffness \Delta (Nm/deg)','FontSize',14,'Rotation',270)
    view(0,90)

    % figure;
    % surf(gx,gy,grad_diff);
    % colormap(jet(256));
    % xlabel('Lateral Bending Displacement (deg)')
    % ylabel('Flexion-Extension Displacement (deg)')
    % zlabel('Resultant Load (Nm)')
    % camlight right;
    % lighting phong;
    % shading interp
    % axis equal
    % %line(x,y,z,'marker','.','markersize',4,'linestyle','none');
    % title('Gradient Gridfit')
    % hold off
end