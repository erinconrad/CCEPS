%% relate connectivity to outcome
clear

% pick a stim electrode of interest
stim_elecs = {'LA','LB','LC';'RA','RB','RC'};

% file locs
locations = cceps_files;

% point to ccep files
ccep_folder = [locations.results_folder,'out_files/'];
listing = dir([ccep_folder,'*HUP*.mat']); % hup patients

nfiles = length(listing);

% prepare variables
name = cell(nfiles,1);
avg_n1 = nan(nfiles,2);
avg_n2 = nan(nfiles,2);

for i = 1:nfiles
    
    % load the file
    out = load([ccep_folder,listing(i).name]);
    out = out.out;

    % patient name
    C = strsplit(out.name,'_');
    hup_name = C{1};
    name{i} = hup_name;

    % loop over electrodes
    n1s = cell(size(stim_elecs,1),size(stim_elecs,2));
    n2s = cell(size(stim_elecs,1),size(stim_elecs,2));

    % Loop over left vs rihgt
    for is = 1:size(stim_elecs,1)

        % Loop over different electrodes on that side
        for js = 1:size(stim_elecs,2)
    
            % find all contacts on that electrode
            idx = contains(out.chLabels,stim_elecs{is,js});
    
            % get the avg connectivity
            n1s{is,js} = out.network(1).A(idx,idx);
            n2s{is,js} = out.network(2).A(idx,idx);
    
        end
    end

    % flatten the arrays
    for is = 1:size(stim_elecs,1)
        all_n1s = [];
        all_n2s = [];
        for js = 1:size(stim_elecs,2)
            all_n1s = [all_n1s;reshape(n1s{is,js},size(n1s{is,js},1)*size(n1s{is,js},1),1)];
            all_n2s = [all_n2s;reshape(n2s{is,js},size(n2s{is,js},1)*size(n2s{is,js},1),1)];
        end
       
        % take average across all of them
        avg_n1(i,is) = nanmean(all_n1s);
        avg_n2(i,is) = nanmean(all_n2s);
    end
    
end

table(name,avg_n1,avg_n2)