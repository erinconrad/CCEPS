overwrite = 0;

%% Updated pipeline to run through all patients in an csv file

locations = cceps_files;
data_folder = locations.data_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'new_pipeline/'];

pwfile = locations.pwfile;
login_name = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end


if ~exist(out_folder,'dir'), mkdir(out_folder); end

%% Load patient list
ptT = readtable([data_folder,'master_pt_list.xlsx']);

%% Parse instances with multiple files
for i = 1:height(ptT)
    % Check if the name contains a comma
    if contains(ptT.ieeg_filename{i}, ',')
        % Split the string by comma and convert to cell array
        ptT.ieeg_filename{i} = strsplit(ptT.ieeg_filename{i}, ',');
    end
end

%% Loop through patients
for i = 1:height(ptT)
    fprintf('\nDoing patient %d of %d...\n',i,height(ptT));
    name = ptT.HUPID{i};
    filenames = ptT.ieeg_filename{i};
    out_file_name =[name,'.mat'];

    if exist([out_folder,out_file_name],'file') ~= 0
        if overwrite == 0
            fprintf('Skipping %s\n',name);
            continue
        else
            fprintf('Overwriting %s\n',name);
        end
    else
        fprintf('Doing %s for the first time\n',name);
    end

    
    tic

    
    
    % Do the patient-level function
    pt_out = pt_pipeline_v2(filenames,login_name,pwfile);
    pt_out.name = name;

    % Save the patient output file
    
    save([out_folder,out_file_name],'pt_out')

    % do validation code
    validation_folder = [out_folder,'validation/',name,'/'];
    if ~exist(validation_folder,'dir'), mkdir(validation_folder); end
    random_rejections_keeps(pt_out,validation_folder);

    t = toc;
    fprintf('Finished in %1.1f seconds.\n',t)
end