function pull_and_show_sz_annotations

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

script_data_folder = [script_folder,'clinical_info/'];

%% Load pt struct
pt = load([script_data_folder,'pt.mat']);
pt = pt.pt;
npts = length(pt);

% Loop over pts
for i = 1:npts
    
    % Loop over main ieeg files
    nfiles = length(pt(i).clinical.main_ieeg_file);
    for f = 1:nfiles
        file = pt(i).clinical.main_ieeg_file{f};
        
        
        % grab annotations
        layer = grab_annotations(file, loginname, pwfile);
        
        % get seizure-y annotations
        [poss_sz_start,poss_sz_text] = find_seizure_annotations_cceps(layer);
        file_names = repmat(file,size(poss_sz_start,1),1);
        
        T = table(file_names,poss_sz_start,poss_sz_text);
        
        % add to structure
        pt(i).file(f).name = file;
        pt(i).file(f).poss_sz_table = T;
        
    end
    
end

%% Re-save
save([script_data_folder,'pt.mat'],'pt');

end