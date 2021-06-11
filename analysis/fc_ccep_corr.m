
clearvars -except pout out

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));


do_binary = 0;
show_labels = 0;

%% Get stim labels
chLabels = out.chLabels;
stim_labels = out.ch_info.stim_labels;
response_labels = out.ch_info.response_labels;

% which response labels are also stim
is_stim = ismember(response_labels,stim_labels);
is_response = ismember(stim_labels,response_labels);
is_both = ismember(chLabels,stim_labels) & ismember(chLabels,response_labels);
restricted_labels = chLabels(is_both);

%% Reduce A to just restricted
A = out.A;
B = A(is_stim,is_response);

%% Get PC labels
pc_labels = pout.keep_labels;
is_pc = ismember(restricted_labels,pc_labels);

%% Build final CCEP network
final_labels = restricted_labels(is_pc);
ccep = B(is_pc,is_pc);
% make nans zero
ccep(isnan(ccep)) = 0;


%% Get pc network
pc = pout.car_pc;
pc_labels = pout.keep_labels;
is_ccep_label = ismember(pc_labels,final_labels);
pc = pc(is_ccep_label,is_ccep_label);

if ~isequal(size(ccep),size(pc))
    error('oh no')
end

if do_binary == 1
    
    
    
    %% Turn matrices into binary versions
    all_cors = (pc(:));
    top_5 = prctile(all_cors,95);
    pc((pc)<top_5) = nan;

    % same for ccep
    ccep(ccep==0) = nan;
    
    % Degrees
    ns = sum(~isnan(pc),2);
    outdegree = sum(~isnan(ccep),2);
    indegree = sum(~isnan(ccep),1)';
    
    
else

    %% Correlate outdegree and ns
    ns = nansum(pc,2);
    outdegree = nansum(ccep,2);
    indegree = nansum(ccep,1)';
    

end
degree_centrality = outdegree+indegree;
flow = outdegree-indegree;
[rout,pou] = corr(ns,outdegree);
[rin,pin] = corr(ns,indegree);
[rcen,pcen] = corr(ns,degree_centrality);
[rflow,pflow] = corr(ns,flow);

%% Make plots
figure
set(gcf,'position',[100 100 800 800])
tiledlayout(3,2,'TileSpacing','compact','padding','compact')
nexttile
turn_nans_white_ccep(ccep)
title('CCEP')
xticks(1:length(final_labels))
xticklabels(final_labels)
yticks(1:length(final_labels))
yticklabels(final_labels)

nexttile
turn_nans_white_ccep(pc)
title('Resting PC')
xticks(1:length(final_labels))
xticklabels(final_labels)
yticks(1:length(final_labels))
yticklabels(final_labels)

if show_labels
    col = [1 1 1];
else
    col = [0 0 0];
end
    

nexttile
plot(ns,outdegree,'o','color',col)
if show_labels
    text(ns,outdegree,final_labels,'horizontalalignment','center')
end
xlabel('PC node strength')
ylabel('CCEP outdegree')
yl = ylim;xl = xlim;
text(xl(1)+0.02*(xl(2)-xl(1)),yl(1)+0.9*(yl(2)-yl(1)),...
    sprintf('r = %1.2f\np = %1.3f',rout,pou))


nexttile
plot(ns,indegree,'o','color',col)
if show_labels
    text(ns,indegree,final_labels,'horizontalalignment','center')
end
xlabel('PC node strength')
ylabel('CCEP indegree')
xl = xlim; yl = ylim;
text(xl(1)+0.02*(xl(2)-xl(1)),yl(1)+0.9*(yl(2)-yl(1)),...
    sprintf('r = %1.2f\np = %1.3f',rin,pin))

nexttile
plot(ns,degree_centrality,'o','color',col)
if show_labels
    text(ns,degree_centrality,final_labels,'horizontalalignment','center')
end
xlabel('PC node strength')
ylabel('CCEP degree centrality')
yl = ylim;xl = xlim;
text(xl(1)+0.02*(xl(2)-xl(1)),yl(1)+0.9*(yl(2)-yl(1)),...
    sprintf('r = %1.2f\np = %1.3f',rcen,pcen))

nexttile
plot(ns,flow,'o','color',col)
if show_labels
    text(ns,flow,final_labels,'horizontalalignment','center')
end

xlabel('PC node strength')
ylabel('CCEP flow')
yl = ylim;xl = xlim;
text(xl(1)+0.02*(xl(2)-xl(1)),yl(1)+0.9*(yl(2)-yl(1)),...
    sprintf('r = %1.2f\np = %1.3f',rflow,pflow))

if 1
while 1
    try
        [x,y] = ginput;
    catch
        break
    end
    if length(x) > 1, x = x(end); end
    if length(y) > 1, y = y(end); end
    
    % Get correspondng stim and response
    x = round(x);
    y = round(y);
    stim_label = final_labels{x}; response_label = final_labels{y};
    figure
    set(gcf,'position',[215 385 1226 413])
    tight_subplot(1,1,[0.01 0.01],[0.15 0.10],[.02 .02]);
    show_avg(out,stim_label,response_label,0)
    
    pause
    close(gcf)
end
end
    
