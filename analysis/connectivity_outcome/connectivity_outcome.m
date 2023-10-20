%% relate connectivity to outcome
clear

% pick a stim electrode of interest
stim_elecs = {'LA','LB','LC'};

% file locs
locations = cceps_files;

% point to ccep files
ccep_folder = [locations.results_folder,'out_files/'];
listing = dir([ccep_folder,'*HUP*.mat']); % hup patients

nfiles = length(listing);

% prepare variables
name = cell(nfiles,1);
avg_n1 = nan(nfiles,1);
avg_n2 = nan(nfiles,1);

for i = 1:nfiles
    
    % load the file
    out = load([ccep_folder,listing(i).name]);
    out = out.out;

    % patient name
    C = strsplit(out.name,'_');
    hup_name = C{1};
    name = [name;hup_name];

    % loop over electrodes
    n1s = cell(length(stim_elecs),1);
    n2s = cell(length(stim_elecs),1);
    for is = 1:length(stim_elecs)

        % find all contacts on that electrode
        idx = contains(out.chLabels,stim_elecs{is});

        % get the avg connectivity
        n1s{is} = out.network(1).A(idx,idx);
        n2s{is} = out.network(2).A(idx,idx);

    end

    % flatten the arrays
    all_n1s = [];
    all_n2s = [];
    for is = 1:length(stim_elecs)
        all_n1s = [all_n1s;reshape(n1s{is},size(n1s{is},1)*size(n1s{is},1),1)];
        all_n2s = [all_n2s;reshape(n2s{is},size(n2s{is},1)*size(n2s{is},1),1)];
    end
   

    avg_n1 = [avg_n1;nanmean(all_n1s)];
    avg_n2 = [avg_n2;nanmean(all_n2s)];
    
end

table(name,avg_n1,avg_n2)