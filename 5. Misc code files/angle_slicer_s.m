function [slice_points,slice_results] = angle_slicer_s(inside_x_mesh, inside_y_mesh,inside_z_mesh,stiffness_mesh,slice_angle,tolerance) % slice_angle is radians, tolerance is degrees
    [inside_theta, inside_rho] = cart2pol(inside_x_mesh, inside_y_mesh);     
    inside_theta = mod(inside_theta + 2*pi, 2*pi);
    theta_rad = slice_angle; %deg2rad(slice_angle);
    explementary_theta = 2*pi-theta_rad;%mod(2*pi - theta_rad, 2*pi);
    
    angle_diff_main = abs(atan2(sin(inside_theta - theta_rad), cos(inside_theta - theta_rad)));
    angle_diff_expl = abs(atan2(sin(inside_theta - explementary_theta), cos(inside_theta - explementary_theta)));
    
    idx_main = find(angle_diff_main < deg2rad(tolerance));
    idx_expl = find(angle_diff_expl < deg2rad(tolerance));

    r_main = inside_rho(idx_main);
    z_main = inside_z_mesh(idx_main);
    s_main = stiffness_mesh(idx_main);
    
    r_expl = -inside_rho(idx_expl);
    z_expl = -inside_z_mesh(idx_expl);
    s_expl = stiffness_mesh(idx_expl);
    
    r_combined = [r_main; r_expl];
    z_combined = [z_main; z_expl];
    s_combined = [s_main; s_expl];
    slice_points = [r_combined, z_combined, s_combined];

    if isempty(r_combined)
        warning("No data for angle %.1f°", slice_angle);
        %continue;
    end

    % Fit polynomial
    poly_degree = 3; % Change this as needed
    coeffs = polyfit(r_combined, z_combined, poly_degree);
    z_fit = polyval(coeffs, r_combined);

    coeffs_s = polyfit(r_combined, s_combined, poly_degree);
    s_fit = polyval(coeffs_s, r_combined);
    
    % R² calculation
    SS_res = sum((z_combined - z_fit).^2);
    SS_tot = sum((z_combined - mean(z_combined)).^2);
    R_squared = 1 - SS_res / SS_tot;
    
    slice_results = [slice_angle, coeffs, R_squared, coeffs_s];
    
    % Plotting
    % figure;
    % scatter(r_combined, z_combined, 5, 'k'); hold on;
    % r_fit = linspace(min(r_combined), max(r_combined), 200);
    % z_fit_plot = polyval(coeffs, r_fit);
    % plot(r_fit, z_fit_plot, 'r-', 'LineWidth', 1.2);
    %title(sprintf('\\theta = %d°, R^2 = %.2f', theta_deg, R_squared));
    %xlabel('R'); ylabel('Z'); grid on;
    % Save individual figure
    % saveas(gcf, sprintf('PolyFit_Theta_%d.png', theta_deg));
    % Or use exportgraphics for higher quality (newer MATLAB)
    % exportgraphics(gcf, sprintf('PolyFit_Theta_%d.pdf', theta_deg), 'ContentType', 'vector');
end