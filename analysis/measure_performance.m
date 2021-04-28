function measure_performance

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

listing = dir([results_folder,'*.mat']);

all_names = {};
all_current = {};
all_stim = [];
all_missing = [];
all_extra = [];

% Loop through result output structures
for i = 1:length(listing)
    fname = listing(i).name;
    C = strsplit(fname,'_');
    pt_name = [C{2},'_',C{3}];
    pt_name = strrep(pt_name,'.mat','');
    
    %% Load the structure
    out = load([results_folder,fname]);
    out = out.out;
    
    %% Get clinical info
    if ~isfield(out,'clinical')
        clinical = pull_clinical_info(pt_name);
    else
        clinical = out.clinical;      
    end
    
    %% Get performance measures
    n_true_stim = length(clinical.stim_electrodes);
    current = clinical.current;
    if strcmp(class(current),'double')
        current = sprintf('%d',current);
    end
    n_missing = length(out.missing);
    n_extra = length(out.extra);
    
    %% Output to main arrays
    all_names = [all_names;pt_name];
    all_current = [all_current;current];
    all_stim = [all_stim;n_true_stim];
    all_missing = [all_missing;n_missing];
    all_extra = [all_extra;n_extra];
    
end

%% Make a table
T = table(all_names,all_current,all_stim,all_missing,all_extra)

%% Save the table
writetable(T,[results_folder,'performance_info.csv']);

end