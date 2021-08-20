function dist_corr_all

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

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

% Load elecs file
info = load([results_folder,'elecs.mat']);
info = info.info;

for i = 1:length(all_names)
    dataName = all_names{i};
    fprintf('\nDoing %s\n',dataName);
    
    
    % Load cceps out file
    out = load([results_folder,'out_files/results_',dataName,'.mat']);
    out = out.out;
    
    % Get correct pt in info file
    foundit = 0;
    for f = 1:length(info)
        if contains(dataName,info(f).name)
            foundit = 1;
            break
        end
    end
    if foundit == 0, error('why'); end
    if isempty(info(f).elecs), fprintf('\nSkipping %s\n',info(f).name); continue; end
    
    corr_dist_ccep(out,info(f).elecs(end));
    
end


end