%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;

% add paths
addpath(genpath(script_folder));

% Load stim table
file_name = 'Stim info.xlsx';

% Get sheetnames
if exist('sheetnames') == 0
    [~,sn,~] = xlsfinfo(file_name);
else
    sn = sheetnames(file_name);
end

all_names = {};
for s = 1:length(sn)
    review_waveforms(sn{s})
    
    
end