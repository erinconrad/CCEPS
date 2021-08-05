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
    subj = (sn{s});
    out = load([[locations.results_folder,'out_files/results_'],subj,'_CCEP.mat']);
    out = out.out;
    random_rejections_keeps(out)
    clear out
    clear subj
    
end