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
results_table = [];

fprintf('Starting parameter sweep and saving to CSV...\n');

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
            
            % Add to results table
            row = [shape_idx, mu, fo, phi_A, phi_B, phi_C, phi_T, phi_0, phi_1, flag_A, flag_B, flag_C];
            results_table = [results_table; row];
            
            fprintf('mu=%.3f, fo=%.3f: phi_T=%.4f\n', mu, fo, phi_T);
        end
    end
end

% Save to CSV file
header = 'shape_idx,mu,fo,phi_A,phi_B,phi_C,phi_T,phi_0,phi_1,flag_A,flag_B,flag_C';

% Write header
fid = fopen('results.csv', 'w');
fprintf(fid, '%s\n', header);
fclose(fid);

% Write data
dlmwrite('results.csv', results_table, '-append', 'delimiter', ',', 'precision', 6);

% Also save shape names
shape_file = fopen('shape_names.txt', 'w');
for i = 1:length(shapes)
    fprintf(shape_file, '%d,%s\n', i, shapes{i});
end
fclose(shape_file);

fprintf('\nResults saved to results.csv and shape_names.txt\n');