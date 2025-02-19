%% uab_dist_corr

locations = cceps_files;
data_folder = locations.data_folder;
results_folder = locations.results_folder;
uab_results_folder = [results_folder,'uab_results/'];
uab_data_folder = [data_folder,'UAB_CCEPS/'];

% Loop through output files
listing = dir([uab_results_folder,'*.mat']);

corr_and_ci = nan(2,3);

for i = 1:length(listing)
    fname = listing(i).name;
    
    out = load([uab_results_folder,fname]);
    out = out.out;

    name = convertStringsToChars(out.name);

    % Load the locations file
    T = readtable([uab_data_folder,name,'_sEEG_Locations_Talairach.csv']);
    locs = [T.x_mm_,T.y_mm_,T.z_mm_];
    dist = make_dist_network(locs);

    % label reconciliation
    loc_labels = T.Label;
    chLabels = out.chLabels;
    % Find common channels and their indices in both arrays
    [matchingChannels, idx_ch, idx_loc] = intersect(chLabels, loc_labels);

    % Extract and align the sub-networks for the matching channels
    matchedDist = dist(idx_loc,idx_loc);  
    matchedN1 = out.network(1).A0(idx_ch,idx_ch);
    matchedN2 = out.network(2).A0(idx_ch,idx_ch);

    % prep data for bootstrap CIs
    which_chs = 1:size(matchedDist,1);
    ci = bootci(1e3,@(x) corr_boot(x,matchedN1,matchedDist),which_chs);
    mean_corr = corr(matchedDist(:),matchedN1(:),'type','spearman','rows','pairwise');
    corr_and_ci(i,:) = [mean_corr,ci'];

end


function r = corr_boot(chs,matchedN1,matchedDist)
    dist_net = matchedDist(chs,chs);
    n1_net = matchedN1(chs,chs);
    r = corr(dist_net(:),n1_net(:),'type','spearman','rows','pairwise');

end