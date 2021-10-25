function build_pt_struct

%% Parameters
overwrite = 0;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end
script_data_folder = [script_folder,'support/clinical_info/'];

file_name = 'Stim info.xlsx';

%% Load existing pt struct
pt = load([script_data_folder,'pt.mat']);
pt = pt.pt;

%% Add patients to structure
% Get sheetnames
if exist('sheetnames') == 0
    [~,sn,~] = xlsfinfo(file_name);
else
    sn = sheetnames(file_name);
end

for s = 1:length(sn)
    T = readtable(file_name,'Sheet',s);
    pt_name = sn(s);
    
    % See if already exists in patient structure, in which case skip it
    if overwrite == 0
        skip = 0;
        for j = 1:length(pt)
            if strcmp(pt_name,pt(j).name)
                skip = 1;
                break
            end     
        end
        if skip, continue; end
    end
    
    pt(end+1).name = pt_name;
    pt(end).clinical = pull_clinical_info(sn(s));
end


%% Save it
save([script_data_folder,'pt.mat'],'pt');

end