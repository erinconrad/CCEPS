%% do_all_uab_pts

locations = cceps_files;
data_folder = [locations.data_folder,'UAB_CCEPs/'];
results_folder = locations.results_folder;
out_folder = [results_folder,'uab_results/'];

script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end


%% Loop over the mat files and run the pipeline
listing = dir([data_folder,'*.mat']);
for i = 1:length(listing)

    if strcmp(listing(i).name{1:2},'._')
        continue
    end

    fpath = [listing(i).folder,'/',listing(i).name];
    dat = load(fpath);
    fname = fieldnames(dat);
    dat = dat.(fname{1});

    name = convertStringsToChars(dat.name);
    out = run_uab_pipeline(dat);

    % Save the output
    save([out_folder,name,'.mat'],"out");

end
