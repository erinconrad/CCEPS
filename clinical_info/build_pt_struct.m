function build_pt_struct

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

file_name = 'Stim info.xlsx';

% Get sheetnames
if exist('sheetnames') == 0
    [~,sn,~] = xlsfinfo(file_name);
else
    sn = sheetnames(file_name);
end

for s = 1:length(sn)
    T = readtable(file_name,'Sheet',s);
    
    pt(s).name = sn(s);
    pt(s).clinical = pull_clinical_info(sn(s));
    
end


%% Save it
script_data_folder = [script_folder,'clinical_info/'];
save([script_data_folder,'pt.mat'],'pt');

end