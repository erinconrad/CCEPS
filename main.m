%% prior to running this, run redo_all_files.m

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;

% add paths
addpath(genpath(script_folder));


%% add electrode coordinates to results file
add_elec_coords

%% compute N1 and N2 networks separately and store
waveform_network

%% compare distance and connectivity in electrode space
distance_connectivity

%% compare N1 and N2 networks in electrode space
n1_vs_v2

%% assign electrodes to MNI space neuroimaging parcellations and parcellate CCEPs networks for N1 and N2
parcellate

%% create group network
group_network

%% compare distance and connectivity in atlas space
group_distance_conn

%% for brainnetome atlas, save FC and SC
brainnetome_sc_fc