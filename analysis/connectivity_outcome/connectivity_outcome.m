%% relate connectivity to outcome

% pick a single stim electrode
stim_elec = 'LA1';

% file locs
locations = cceps_files;

% point to ccep files
ccep_folder = [locations.results_folder,'out_files/'];
listing = dir([ccep_folder,'*HUP*.mat']); % hup patients

nfiles = length(listing);

% prepare variables
name = {};
avg_n1 = [];
avg_n2 = [];

for i = 1:nfiles
    
    % load the file
    out = load([ccep_folder,listing(i).name]);
    out = out.out;

    % find index of chosen electrode
    chosen_idx = strcmp(out.chLabels,stim_elec);

    % skip if the patient doesn't have it
    if sum(chosen_idx) == 0, continue; end

    % skip if we didn't stim it
    if out.stim_chs(chosen_idx) == 0, continue; end

    % if made it to here, include this patient
    C = strsplit(out.name,'_');
    hup_name = C{1};
    name = [name;hup_name];

    % get the average connectivity between this chosen contact and other
    % contacts on the same electrode
    other_contacts = contains(out.chLabels,stim_elec(1:2));
    n1 = out.network(1).A(chosen_idx,other_contacts);
    n2 = out.network(2).A(chosen_idx,other_contacts);

    avg_n1 = [avg_n1;nanmean(n1)];
    avg_n2 = [avg_n2;nanmean(n2)];
    
end

table(name,avg_n1,avg_n2)