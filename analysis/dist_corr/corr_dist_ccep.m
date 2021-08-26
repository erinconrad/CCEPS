function corr_dist_ccep(out,elecs)

do_log=1;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'analysis/dist_corr/'];
if ~exist(out_folder,'dir'), mkdir(out_folder); end
name = out.name;
C = strsplit(name,'_');
pt_name = C{1};

% add paths
addpath(genpath(script_folder));

%% Get data
if do_log ==1
    ccep = log(out.A);
else
    ccep = out.A;
end
ccep_bipolar_labels = out.bipolar_labels;

locs = elecs(1).locs;
loc_labels = elecs(1).elec_names;

%% Get inv distance network for bipolar locs
% Get the indices in locs of the bipolar chs
idx = find_labels_in_bipolar(ccep_bipolar_labels,loc_labels);

% get the location of the midpoint between each ch pair
bi_locs = get_bipolar_locs(idx,locs);

% Get inverse dis
inv_dist_net = make_dist_network(bi_locs);

%% Do correlations
% Get ccep upper triangle
ut = logical(triu(ones(size(ccep))));
ccep_ut = ccep(ut);

% Get ccep lower triangle
lt = logical(tril(ones(size(ccep))));
ccep_lt = ccep(lt);

% Get dist ut (same either way)
dist_ut = inv_dist_net(ut);
dist_lt = inv_dist_net(lt);

% do correlations
ru = corr(ccep_ut,dist_ut,'rows','pairwise');
rl = corr(ccep_lt,dist_lt,'rows','pairwise');

% Plot them
all_nans = sum(~isnan(inv_dist_net),1) == 0;
figure
tiledlayout(2,2,'tilespacing','tight','padding','tight')
nexttile
turn_nans_white_ccep(ccep(~all_nans,~all_nans))
xticklabels([])
yticklabels([])
title('CCEP')

nexttile
turn_nans_white_ccep(inv_dist_net(~all_nans,~all_nans))
xticklabels([])
yticklabels([])
title('1/dist')

nexttile
plot(dist_ut,ccep_ut,'o')
xlabel('1/dist')
ylabel('CCEP upper triangle')
title(sprintf('r = %1.2f',ru))

nexttile
plot(dist_lt,ccep_lt,'o')
xlabel('1/dist')
ylabel('CCEP lower triangle')
title(sprintf('r = %1.2f',rl))

if do_log
    print(gcf,[out_folder,pt_name,'_log'],'-dpng');
else
    print(gcf,[out_folder,pt_name],'-dpng');
end
close(gcf)
end