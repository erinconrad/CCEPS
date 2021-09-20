%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;

% add paths
addpath(genpath(script_folder));

subjs = locations.subjects;
for s = 1:length(subjs)
    load([[locations.results_folder,'out_files/results_'],subjs{s},'_CCEP.mat']);
    review_waveforms(out,subjs{s},locations)    
end