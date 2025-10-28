clear; close all; clc;

warning off;
% Add the polyhedron function path
addpath('./Polyhedron-function')

%%% Colors %%%
purple = [107.0/255, 62.0/255, 154.0/255];
blue = [0, 64.0/255, 128.0/255];
red = [180.0/255, 7.0/255, 5.0/255];
green = [0.0/255, 112/255, 0.0/255];
yellow = [241, 194, 50]/255;
colors = {red, blue, purple, green, yellow};
%%%%%%%%%%%%%%

%%% Load mesh %%%
% Define shape - let's start with RhombicDodecahedron
verts_name = 'RhombicDodecahedron';
mesh_name = strcat(lower(verts_name),'_mesh.mat');
% Load
mesh_data = load(mesh_name);
omega_original = mesh_data.omega;
% Current directory
current_path = pwd;
%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PARAMETERS TO CHANGE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Chemical potential (controls concentration [I])
mu = -0.175;

% Grafting density
fo = 0.1;

% Chain-chain attraction
chi = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Determine grafting ratio %%%
% Energy
eps_A = 1;
eps_B = 1;
eps_C = -1;
% Surface packing
rho_ref = 0.9;
rho_A = 0.79/rho_ref;
rho_B = 0.56/rho_ref;
rho_C = 0.9/rho_ref;
% Power Scaling
ppower = 3/3;
rho_A = rho_A.^ppower;
rho_B = rho_B.^ppower;
rho_C = rho_C.^ppower;
% Temperature
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
    % Scale
    phi_Brel = phi_B/(phi_B+phi_C);
    phi_Crel = phi_C/(phi_B+phi_C);
    % Define working probability
    phi_0 = phi_Crel;
    phi_1 = phi_Brel;
elseif flag_B == 0
    phi_B = 0*phi_B;
    % Scale
    phi_Arel = phi_A/(phi_A+phi_C);
    phi_Crel = phi_C/(phi_A+phi_C);
    % Define working probability
    phi_0 = phi_Crel;
    phi_1 = phi_Arel;
elseif flag_C == 0
    phi_C = 0*phi_C;
    % Scale
    phi_Arel = phi_A/(phi_A+phi_B);
    phi_Brel = phi_B/(phi_A+phi_B);
    % Define working probability
    phi_0 = phi_Arel;
    phi_1 = phi_Brel;
end  

fprintf('Results for %s:\n', verts_name);
fprintf('phi_A = %.4f, phi_B = %.4f, phi_C = %.4f\n', phi_A, phi_B, phi_C);
fprintf('phi_T = %.4f, phi_0 = %.4f, phi_1 = %.4f\n', phi_T, phi_0, phi_1);
fprintf('Chemical potential mu = %.3f\n', mu);
fprintf('Grafting density fo = %.3f\n', fo);

% Save results
results.verts_name = verts_name;
results.phi_A = phi_A;
results.phi_B = phi_B;
results.phi_C = phi_C;
results.phi_T = phi_T;
results.phi_0 = phi_0;
results.phi_1 = phi_1;
results.mu = mu;
results.fo = fo;
results.chi = chi;

save('corona_results.mat', 'results');
fprintf('Results saved to corona_results.mat\n');