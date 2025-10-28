clear; close all; clc;

warning off;
% Add the polyhedron function path
addpath('./Polyhedron-function')

% Define shapes to test (matching the paper)
shapes = {'Octahedron', 'RhombicDodecahedron', 'Cuboctahedron'};

% Define parameter ranges to sweep
mu_values = [-0.3, -0.25, -0.2, -0.175, -0.15, -0.1, -0.05];  % Chemical potential
fo_values = [0.05, 0.1, 0.15, 0.2];  % Grafting density

% Initialize results storage
all_results = {};
result_counter = 1;

fprintf('Starting parameter sweep...\n');
fprintf('Testing %d shapes, %d mu values, %d fo values\n', length(shapes), length(mu_values), length(fo_values));

for shape_idx = 1:length(shapes)
    verts_name = shapes{shape_idx};
    fprintf('\n=== Testing shape: %s ===\n', verts_name);
    
    % Check if mesh file exists
    mesh_name = strcat(lower(verts_name),'_mesh.mat');
    if ~exist(mesh_name, 'file')
        fprintf('Warning: Mesh file %s not found, skipping...\n', mesh_name);
        continue;
    end
    
    % Load mesh
    mesh_data = load(mesh_name);
    omega_original = mesh_data.omega;
    
    for mu_idx = 1:length(mu_values)
        mu = mu_values(mu_idx);
        
        for fo_idx = 1:length(fo_values)
            fo = fo_values(fo_idx);
            
            % Fixed parameters
            chi = 0;
            eps_A = 1;
            eps_B = 1;
            eps_C = -1;
            rho_ref = 0.9;
            rho_A = 0.79/rho_ref;
            rho_B = 0.56/rho_ref;
            rho_C = 0.9/rho_ref;
            ppower = 3/3;
            rho_A = rho_A.^ppower;
            rho_B = rho_B.^ppower;
            rho_C = rho_C.^ppower;
            kT = 0.5;
            
            % Flag for removing certain facets
            if strcmp(verts_name,'Octahedron') == 1
                flag_A = 1;
                flag_B = 0;
                flag_C = 1;
            elseif strcmp(verts_name,'RhombicDodecahedron') == 1
                flag_A = 0;
                flag_B = 1;
                flag_C = 1;
            elseif strcmp(verts_name,'Cuboctahedron') == 1
                flag_A = 1;
                flag_B = 0;
                flag_C = 1;
            elseif strcmp(verts_name,'trunc_tetra') == 1
                flag_A = 1;
                flag_B = 0;
                flag_C = 1;
            elseif strcmp(verts_name,'Dipyramid5') == 1
                flag_A = 1;
                flag_B = 0;
                flag_C = 1;
            end
            
            % Working terms
            D_A = exp( flag_A*(1/kT).*(eps_C.*rho_A - mu) );
            D_B = exp( flag_B*(1/kT).*(eps_C.*rho_B - mu) );
            D_C = exp( flag_C*(1/kT).*(eps_C.*rho_C - mu) );
            
            % A Type Fraction
            phi_A1 = 1 - D_A./(1+D_B+D_B.*D_A);
            phi_A2 = D_C + D_A./(1+D_A).*(1 - D_A./(1+D_B+D_B.*D_A));
            phi_A = D_C./(1+D_A).*phi_A1./phi_A2;
            
            % B Type Fraction
            phi_B1 = D_C.*D_A./(1+D_B+D_B.*D_A);
            phi_B2 = D_C + D_A./(1+D_A).*(1 - D_A./(1+D_B+D_B.*D_A));
            phi_B = phi_B1./phi_B2;
            
            % C Type Fraction
            phi_C1 = D_A./(1+D_A).*(1-D_A./(1+D_B+D_B.*D_A));
            phi_C = phi_C1./(D_C+phi_C1);
            
            % Initial
            phi_Tinit = phi_A + phi_B + phi_C;
            
            % Check flags
            if flag_A == 0
                phi_A = 0*phi_A;
            elseif flag_B == 0
                phi_B = 0*phi_B;
            elseif flag_C == 0
                phi_C = 0*phi_C;
            end  
            
            % Combine
            phi_T = phi_A + phi_B + phi_C;
            
            % Define relative probability
            if flag_A == 0
                phi_A = 0*phi_A;
                phi_Brel = phi_B/(phi_B+phi_C);
                phi_Crel = phi_C/(phi_B+phi_C);
                phi_0 = phi_Crel;
                phi_1 = phi_Brel;
            elseif flag_B == 0
                phi_B = 0*phi_B;
                phi_Arel = phi_A/(phi_A+phi_C);
                phi_Crel = phi_C/(phi_A+phi_C);
                phi_0 = phi_Crel;
                phi_1 = phi_Arel;
            elseif flag_C == 0
                phi_C = 0*phi_C;
                phi_Arel = phi_A/(phi_A+phi_B);
                phi_Brel = phi_B/(phi_A+phi_B);
                phi_0 = phi_Arel;
                phi_1 = phi_Brel;
            end  
            
            % Store results
            all_results{result_counter}.shape = verts_name;
            all_results{result_counter}.mu = mu;
            all_results{result_counter}.fo = fo;
            all_results{result_counter}.phi_A = phi_A;
            all_results{result_counter}.phi_B = phi_B;
            all_results{result_counter}.phi_C = phi_C;
            all_results{result_counter}.phi_T = phi_T;
            all_results{result_counter}.phi_0 = phi_0;
            all_results{result_counter}.phi_1 = phi_1;
            all_results{result_counter}.flag_A = flag_A;
            all_results{result_counter}.flag_B = flag_B;
            all_results{result_counter}.flag_C = flag_C;
            
            fprintf('mu=%.3f, fo=%.3f: phi_T=%.4f, phi_A=%.4f, phi_B=%.4f, phi_C=%.4f\n', ...
                    mu, fo, phi_T, phi_A, phi_B, phi_C);
            
            result_counter = result_counter + 1;
        end
    end
end

% Save all results
save('parameter_sweep_results.mat', 'all_results');
fprintf('\nParameter sweep complete! Results saved to parameter_sweep_results.mat\n');
fprintf('Total %d parameter combinations tested.\n', length(all_results));