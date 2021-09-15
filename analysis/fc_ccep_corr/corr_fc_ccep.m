function corr_fc_ccep(out)

do_log=1;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'analysis/fc_corr/'];
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


%% Get FC network
% Get the indices in locs of the bipolar chs
pc = out.avg_pc;

%% Do correlations
% Get ccep upper triangle
ut = logical(triu(ones(size(ccep))));
ccep_ut = ccep(ut);

% Get ccep lower triangle
lt = logical(tril(ones(size(ccep))));
ccep_lt = ccep(lt);

% Get pc ut (same either way)
pc_ut = pc(ut);
pc_lt = pc(lt);

% do correlations
ru = corr(ccep_ut,pc_ut,'rows','pairwise');
rl = corr(ccep_lt,pc_lt,'rows','pairwise');

% Plot them
all_nans = sum(~isnan(pc),1) == 0;
figure
tiledlayout(2,2,'tilespacing','tight','padding','tight')
nexttile
turn_nans_white_ccep(ccep(~all_nans,~all_nans))
xticklabels([])
yticklabels([])
title('CCEP')

nexttile
turn_nans_white_ccep(pc(~all_nans,~all_nans))
xticklabels([])
yticklabels([])
title('PC')

nexttile
plot(pc_ut,ccep_ut,'o')
xlabel('PC')
ylabel('CCEP upper triangle')
title(sprintf('r = %1.2f',ru))

nexttile
plot(pc_lt,ccep_lt,'o')
xlabel('PC')
ylabel('CCEP lower triangle')
title(sprintf('r = %1.2f',rl))

if do_log
    print(gcf,[out_folder,pt_name,'_log'],'-dpng');
else
    print(gcf,[out_folder,pt_name],'-dpng');
end
close(gcf)
end