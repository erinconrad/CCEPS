function corr_fc_dist(out,elecs)


%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'analysis/fc_dist_corr/'];
if ~exist(out_folder,'dir'), mkdir(out_folder); end
name = out.name;
C = strsplit(name,'_');
pt_name = C{1};

% add paths
addpath(genpath(script_folder));

%% Get FC network
% Get the indices in locs of the bipolar chs
pc = out.avg_pc;

%% Get inv distance network for bipolar locs
% Get the indices in locs of the bipolar chs
ccep_bipolar_labels = out.bipolar_labels;
locs = elecs(1).locs;
loc_labels = elecs(1).elec_names;

idx = find_labels_in_bipolar(ccep_bipolar_labels,loc_labels);

% get the location of the midpoint between each ch pair
bi_locs = get_bipolar_locs(idx,locs);

% Get inverse dis
inv_dist_net = make_dist_network(bi_locs);


%% Do correlations
% Get ccep upper triangle
ut = logical(triu(ones(size(pc))));

% Get ccep lower triangle
lt = logical(tril(ones(size(pc))));

% Get pc ut (same either way)
pc_ut = pc(ut);
pc_lt = pc(lt);

% Get dist ut (same either way)
dist_ut = inv_dist_net(ut);
dist_lt = inv_dist_net(lt);

% do correlations
ru = corr(dist_ut,pc_ut,'rows','pairwise');
rl = corr(dist_lt,pc_lt,'rows','pairwise');

% Plot them
all_nans = sum(~isnan(pc),1) == 0;
figure
tiledlayout(2,2,'tilespacing','tight','padding','tight')
nexttile
turn_nans_white_ccep(inv_dist_net(~all_nans,~all_nans))
xticklabels([])
yticklabels([])
title('1/dist')

nexttile
turn_nans_white_ccep(pc(~all_nans,~all_nans))
xticklabels([])
yticklabels([])
title('PC')

nexttile
plot(pc_ut,dist_ut,'o')
xlabel('PC')
ylabel('1/dist')
title(sprintf('r = %1.2f',ru))

nexttile
plot(pc_lt,dist_lt,'o')
xlabel('PC')
ylabel('1/dist')
title(sprintf('r = %1.2f',rl))


print(gcf,[out_folder,pt_name],'-dpng');

close(gcf)
end