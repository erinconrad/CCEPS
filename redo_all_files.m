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
    T = readtable(file_name,'Sheet',s);
    
    % Read ieeg name
    curr_name = T.IeegName{1};
    
    all_names = [all_names;curr_name];
end


for i = 1:length(all_names)
    clearvars -except all_names i
    dataName = all_names{i};
    fprintf('\nDoing %s\n',dataName);
    new_cceps
end
