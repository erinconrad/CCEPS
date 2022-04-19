function compare_ccep_symm

%% Parameters
do_log = 1;
do_save = 1;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'out_files/'];
data_folder = locations.data_folder;

if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

% add paths
addpath(genpath(script_folder));

% Loop over out files
listing = dir([out_folder,'*.mat']);
for l = 1:length(listing)
    % Load the file
    out = load([out_folder,listing(l).name]);
    out = out.out;
    
    
end

end