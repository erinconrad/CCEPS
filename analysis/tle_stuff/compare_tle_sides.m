%% compare sides

%% locs
locations = cceps_files;
data_folder = locations.data_folder;
results_folder = locations.results_folder;
inter_folder = [results_folder,'tle/'];

script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

% Load tle file
tle = load([inter_folder,'tle.mat']);
tle = tle.tle;

npts = length(tle);
net_comp = nan(npts,2,2);
for ip = 1:npts
    for in = 1:2

        % first just avg ipisilateral TLE stim and response
        right_idx = ismember(tle(ip).labels,tle(ip).rt_elecs);
        left_idx = ismember(tle(ip).labels,tle(ip).lt_elecs);

        right_avg = nanmean(tle(ip).network(in).A(right_idx,right_idx),'all');
        left_avg = nanmean(tle(ip).network(in).A(left_idx,left_idx),'all');

        net_comp(ip,in,:) = [left_avg,right_avg];
    end
end

%% plot left vs right
figure
for in = 1:2
    if in == 1
        ytext = 'N1';
    else
        ytext = 'N2';
    end
    nexttile
    data = squeeze(net_comp(:,in,:));
    paired_plot_cceps(data(:,1),data(:,2),'left','right',ytext)
end