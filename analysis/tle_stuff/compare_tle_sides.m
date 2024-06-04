%% compare sides

show_nets = 0;

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

% also load file with soz locs and lats
piT = readtable([data_folder,'master_pt_list.xlsx']);

%%
stim_chs = 6:9;
resp_chs = 1:3;

soz_locs = piT.SOZ_loc;
soz_lats = piT.SOZ_lat;

if show_nets
    figure
    tiledlayout(1,2)
end
names = {};
npts = length(tle);
net_comp = nan(npts,2,2);
for ip = 1:npts
    names(end+1) = {tle(ip).name};
    for in = 1:2
        labels = tle(ip).labels;
        labels(cellfun(@isempty,labels)) = {'x'};
        
        % find the labels with the desired numbers
        numericParts = cellfun(@(x) (regexp(x,'\d*','Match')),labels,'uniformoutput',false);
        numericParts(cellfun(@isempty,numericParts)) = {{'0'}};
        % Convert extracted numeric strings to numbers, handling empty cells
        numericParts = cellfun(@(x) str2double(x{1}), numericParts);
        
       
        higher_num_idx = (ismember(numericParts, stim_chs));
        lower_num_idx = (ismember(numericParts, resp_chs));
        %}

        % find left and right temporal
        right_idx = ismember(tle(ip).labels,tle(ip).rt_elecs);
        left_idx = ismember(tle(ip).labels,tle(ip).lt_elecs);
        if sum(right_idx) == 1 || sum(left_idx) == 1
            continue
        end

        right_avg = nanmedian(tle(ip).network(in).A(right_idx & lower_num_idx,...
            right_idx & higher_num_idx),'all');
        left_avg = nanmedian(tle(ip).network(in).A(left_idx & lower_num_idx,...
            left_idx & higher_num_idx),'all');

        climits = [min([min(tle(ip).network(in).A(right_idx,...
            right_idx),[],'all') min(tle(ip).network(in).A(left_idx,...
            left_idx),[],'all')]) max([max(tle(ip).network(in).A(right_idx,...
            right_idx),[],'all') max(tle(ip).network(in).A(left_idx,...
            left_idx),[],'all')])];
        if isempty(climits) || any(isnan(climits))
            climits = [0 1];
        end

        if show_nets
            x_labels = labels;
            x_labels(higher_num_idx) = cellfun(@(x) [x,'***'],x_labels(higher_num_idx),'UniformOutput',false);

            y_labels = labels;
            y_labels(lower_num_idx) = cellfun(@(x) [x,'***'],y_labels(lower_num_idx),'UniformOutput',false);

            nexttile(1)
            clim(climits)
            if ~isempty(tle(ip).network(in).A(left_idx,...
                left_idx))
                turn_nans_gray(tle(ip).network(in).A(left_idx,...
                    left_idx))
                xticks(1:sum(left_idx))
                xticklabels(x_labels(left_idx))
                yticks(1:sum(left_idx))
                yticklabels(y_labels(left_idx))
            else
                plot(1)
            end
            
            colorbar
            title(sprintf('%s: soz %s %s Left stim network',...
                tle(ip).name,soz_lats{ip},soz_locs{ip}))
            hold off
    
            nexttile(2)
            clim(climits)
            if ~isempty(tle(ip).network(in).A(right_idx,...
                right_idx))
                turn_nans_gray(tle(ip).network(in).A(right_idx,...
                    right_idx))
                xticks(1:sum(right_idx))
                xticklabels(x_labels(right_idx))
                yticks(1:sum(right_idx))
                yticklabels(y_labels(right_idx))
            else
                plot(1)
            end
            
            colorbar
            title(sprintf('%s: soz %s %s Right stim network',...
                tle(ip).name,soz_lats{ip},soz_locs{ip}))
    
            
            hold off
            pause
        end

        net_comp(ip,in,:) = [left_avg,right_avg];
    end
end
names = names';

%% Match soz locs and lats with nums
% make sure patients align
assert(isequal(names,piT.HUPID))




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

    % Restrict to unilateral temporal
    unilat_temp = (strcmp(soz_lats,'right')|strcmp(soz_lats,'left')) & ...
        strcmp(soz_locs,'temporal');
    unilat_temp_data = data(unilat_temp,:);
    restrict_lat_info = soz_lats(unilat_temp);
    
    % reorder based on soz
    ipsi = unilat_temp_data;
    ipsi(strcmp(restrict_lat_info,'right'),:) = unilat_temp_data(strcmp(restrict_lat_info,'right'),[2 1]);

    paired_plot_cceps(ipsi(:,1),ipsi(:,2),'ipsi','contra',ytext)
end