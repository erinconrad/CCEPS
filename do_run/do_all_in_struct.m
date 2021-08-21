function do_all_in_struct

%% Parameters
overwrite = 0;
also_validate = 1;

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

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;

for p = 1:length(pt)
    
    fname = pt(p).ccep.file.name;
    
    if exist([out_folder,'results_',fname,'.mat'],'file') ~= 0
        if overwrite == 0
            fprintf('\nAlready did %s, skipping\n',fname);
            continue
        end
    end
    
    if strcmp(pt(p).ccep.file.ann,'empty')
        fprintf('\nNo annotations for %s, skipping\n',fname);
        continue
    end
    
    fprintf('\nDoing %s\n',fname);
    cceps_struct(pt,p);
    
    if also_validate
        fprintf('\nValidating...\n');
        random_rejections_keeps(out)
    end
    
end



end