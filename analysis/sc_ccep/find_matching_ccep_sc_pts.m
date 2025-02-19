function find_matching_ccep_sc_pts

locations = cceps_files;
data_folder = locations.data_folder;
sc_folder = [data_folder,'sc_data/'];

%% Load the structural connectivity file
sc = load([sc_folder,'connectivityIEEGscPenn.mat']);
scT = sc.connectivity;

% Get the SC patients
sc_rids = scT.record_id;
sc_hups = rid_to_hup(sc_rids);
sc_hup_names = arrayfun(@(x) sprintf('HUP%d',x),sc_hups,'UniformOutput',false);

%% Load the master ccep list
mT = readtable([data_folder,'master_pt_list.xlsx']);
ccep_hup_names = mT.HUPID;

%% Find the intersection

end