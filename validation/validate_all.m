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

for s = 1:length(sn)
    subj = (sn{s});
    
    % get ieeg name
    T = readtable(file_name,'sheet',sn{s});
    ieeg_name = T.IeegName{1};
    
    out = load([[locations.results_folder,'out_files/results_'],ieeg_name,'.mat']);
    out = out.out;
    fprintf('\nDoing %s\n',subj);
    random_rejections_keeps(out)
    close all % close figures generated in function
    clear out
    clear subj
    
end