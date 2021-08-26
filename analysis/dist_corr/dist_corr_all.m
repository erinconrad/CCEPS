function dist_corr_all

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_file_folder = [results_folder,'out_files/'];

% add paths
addpath(genpath(script_folder));

% Load elecs file
info = load([results_folder,'elecs.mat']);
info = info.info;

% Get files in the out files folder
listing = dir([out_file_folder,'*.mat']);


for i = 1:length(listing)
    fname = listing(i).name;
    C = strsplit(fname,'_');
    dataName = [C{2},'_',C{3}];
    
    out = load([out_file_folder,fname]);
    out = out.out;
    
    fprintf('\nDoing %s\n',dataName);
    
    
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