%% Parameters
overwrite = 0;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.data_folder;
box_folder = locations.box_folder;
elec_path = [box_folder,'CNT Implant Reconstructions/'];

% add paths
addpath(genpath(script_folder));

% Load stim table
file_name = 'Stim info.xlsx';

% Load the existing elecs file
info = load([results_folder,'elecs.mat']);
info = info.info;

% Get sheetnames
if exist('sheetnames') == 0
    [~,sn,~] = xlsfinfo(file_name);
else
    sn = sheetnames(file_name);
end


for s = 1:length(sn)
    if length(info) >= s
        if isfield(info(s),'elecs')
            if ~isempty(info(s).elecs)
                if overwrite == 0
                    fprintf('\nAlready did %s, skipping...\n',info(s).name);
                    continue
                end
            end
        end
    end
    elecs = return_mni(sn{s},elec_path);
    info(s).name = sn{s};
    info(s).elecs = elecs;
end

% save
save([results_folder,'elecs.mat'],'info')

