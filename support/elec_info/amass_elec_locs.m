%% amass_elec_locs

%% Paths
rid_table = '../../../data/rid_hup2.csv';
pt_table = '../../../data/master_pt_list.xlsx';
pennsieve_path = '../../../../pennsieve_imaging/BIDS_May172025/';
out_path = '../../../results/elec_locs/';

%% start pennsieve agent
system('/usr/local/bin/pennsieve agent')

%% Load tabels
ptT = readtable(pt_table);
ridT = readtable(rid_table);

npts = size(ptT,1);

% Loop over patients
for i = 1:npts

    %% Get the RID
    hup_name = ptT.HUPID{i};
    hup_no = str2num(hup_name(4:end));
    rid_row = ridT.hupsubjno == hup_no;

    if sum(rid_row) ~= 1, continue; end

    rid = ridT.record_id(rid_row);


    %% Attempt to locate the elec loc file
    
    if rid < 100
        rid_name = sprintf('00%d',rid);
    elseif rid < 1000
        rid_name = sprintf('0%d',rid);
    else
        rid_name = sprintf('%d',rid);
    end


    file_path = [pennsieve_path,'sub-RID',rid_name,'/derivatives/ieeg_recon/module3/electrodes2ROI.csv'];

    if exist(file_path,'file') ~= 0
        fprintf('\nCopying %s\n',rid_name);
        system(sprintf('/usr/local/bin/pennsieve map pull %s',file_path));
        pause(1)
        destination = [out_path,hup_name,'/'];
        mkdir(destination);
        copyfile(file_path,destination)
    end


end