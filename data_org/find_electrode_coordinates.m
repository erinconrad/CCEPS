%% This script pulls a list of patients, finds their electrode coordinates, and moves them to a new folder

%% File paths
% Path to file with rids
patient_list_file = '../../data/CNTSurgicalRepositor-Erinprotocolstimr01_DATA_LABELS_2024-10-01_1157.csv';

% parent directory for imaging data
parent_dir1 = '/mnt/leif/littlab/data/Human_Data/CNT_iEEG_BIDS/';
parent_dir2 = '/mnt/leif/littlab/data/Human_Data/recon/BIDS_penn/';

% output
output_folder = '../../cceps_results/elec_info/';

% Load the patient list file
T = readtable(patient_list_file);

missing_rids = [];

% Loop over patients
for r = 1:size(T,1)

    rid = T.RecordID(r);
    if rid<1000
        rids = sprintf('0%d',rid);
    else
        rids = sprintf('%d',rid);
    end

    coor_file = '*atropos*csv';

    sub_dir1 = [parent_dir1,'sub-RID',rids,'/derivatives/ieeg_recon/module3/']; 
    full_file1 = [sub_dir1,coor_file];
    listing1 = dir(full_file1);

    sub_dir2 = [parent_dir2,'sub-RID',rids,'/derivatives/ieeg_recon/module3/'];
    full_file2 = [sub_dir2,coor_file];
    listing2 = dir(full_file2);

    if length(listing1) >0
        listing = listing1;
    else
        listing = listing2;
    end

    if length(listing) == 0
        fprintf('\nWarning, can''t find file for rid %d\n',rid);
        missing_rids = [missing_rids,rid];
    elseif length(listing) == 1
        copyfile([listing(1).folder,'/',listing(1).name],output_folder);
    else
        copyfile([listing(2).folder,'/',listing(2).name],output_folder);
        
    end
end

writematrix(missing_rids,[output_folder,'missing.txt'])