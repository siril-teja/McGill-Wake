function [slice_points] = angle_slicer_hystorder(Data,slice_angle,tolerance) % slice_angle is radians, tolerance is degrees    
    
    theta_rad = slice_angle; % in rad    
    explementary_theta = 2*pi-theta_rad;%mod(2*pi - theta_rad, 2*pi);

    % Inward only
    [in_theta, in_rho] = cart2pol(Data.In_Mesh(:,1), Data.In_Mesh(:,2));
    in_theta = mod(in_theta + 2*pi, 2*pi);  
    
    in_angle_diff_main = abs(atan2(sin(in_theta - theta_rad), cos(in_theta - theta_rad)));
    in_angle_diff_expl = abs(atan2(sin(in_theta - explementary_theta), cos(in_theta - explementary_theta)));
    
    in_idx_main = find(in_angle_diff_main < deg2rad(tolerance));
    in_idx_expl = find(in_angle_diff_expl < deg2rad(tolerance));

    in_r_main = in_rho(in_idx_main);
    in_z_main = Data.In_Mesh(in_idx_main,3);
    %in_s_main = Data.Stiffness(in_idx_main);
    
    in_r_expl = -in_rho(in_idx_expl);
    in_z_expl = -Data.In_Mesh(in_idx_expl,3);
    %in_s_expl = Data.Stiffness(in_idx_expl);

    % Outward only
    [out_theta, out_rho] = cart2pol(Data.Out_Mesh(:,1), Data.Out_Mesh(:,2));
    out_theta = mod(out_theta + 2*pi, 2*pi);  
    
    out_angle_diff_main = abs(atan2(sin(out_theta - theta_rad), cos(out_theta - theta_rad)));
    out_angle_diff_expl = abs(atan2(sin(out_theta - explementary_theta), cos(out_theta - explementary_theta)));
    
    out_idx_main = find(out_angle_diff_main < deg2rad(tolerance));
    out_idx_expl = find(out_angle_diff_expl < deg2rad(tolerance));

    out_r_main = out_rho(out_idx_main);
    out_z_main = Data.Out_Mesh(out_idx_main,3);
    %out_s_main = Data.Stiffness(out_idx_main);
    
    out_r_expl = -out_rho(out_idx_expl);
    out_z_expl = -Data.Out_Mesh(out_idx_expl,3);
    %out_s_expl = Data.Stiffness(out_idx_expl);
    
    if slice_angle>(pi/2)
        r_combined = [flip(out_r_main); in_r_main; flip(out_r_expl); in_r_expl];
        z_combined = [flip(out_z_main); in_z_main; flip(out_z_expl); in_z_expl];
    elseif slice_angle==(pi/2)
        [sout_r_main,out_r_I]=sort(out_r_main);
        sout_z_main=out_z_main(out_r_I);
        [sin_r_main,in_r_I]=sort(in_r_main);
        sin_z_main=in_z_main(in_r_I);
        [sout_r_expl,out_r_expl_I]=sort(out_r_expl);
        sout_z_expl=out_z_expl(out_r_expl_I);
        [sin_r_expl,in_r_expl_I]=sort(in_r_expl);
        sin_z_expl=in_z_expl(in_r_expl_I);

        r_combined = [sout_r_main; flip(sin_r_main); flip(sout_r_expl); sin_r_expl];
        z_combined = [sout_z_main; flip(sin_z_main); flip(sout_z_expl); sin_z_expl];
    else
        r_combined = [out_r_main; flip(in_r_main); out_r_expl; flip(in_r_expl)];
        z_combined = [out_z_main; flip(in_z_main); out_z_expl; flip(in_z_expl)];
    end
    %s_combined = [s_main; s_expl];
    slice_points = [r_combined, z_combined];%, s_combined];

    writematrix(slice_points, 'output.csv');

    % if isempty(r_combined)
    %     warning("No data for angle %.1f°", slice_angle);
    %     %continue;
    % end
    % 
    % % Fit polynomial
    % poly_degree = 3; % Change this as needed
    % coeffs = polyfit(r_combined, z_combined, poly_degree);
    % z_fit = polyval(coeffs, r_combined);
    % 
    % coeffs_s = polyfit(r_combined, s_combined, poly_degree);
    % s_fit = polyval(coeffs_s, r_combined);
    % 
    % % R² calculation
    % SS_res = sum((z_combined - z_fit).^2);
    % SS_tot = sum((z_combined - mean(z_combined)).^2);
    % R_squared = 1 - SS_res / SS_tot;
    % 
    % slice_results = [slice_angle, coeffs, R_squared, coeffs_s];
    

end