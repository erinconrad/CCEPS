
function stats = new_fc_ccep_corr(out,pout,do_plots,do_symmetric)

%% Parameters
do_binary = 0;
do_pretty = 1;
do_log = 0;
do_gui = 0;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

if do_pretty
    show_labels = 0;
else
    show_labels = 1;
end

%% Get CCEP network
ccep = out.A;

%% Get stim labels
chLabels = out.chLabels;
stim_labels = out.ch_info.stim_labels;
response_labels = out.ch_info.response_labels;
is_both = ismember(chLabels,stim_labels) & ismember(chLabels,response_labels);

%% Get PC labels
pc_labels = pout.keep_labels;
is_stim_pc = ismember(stim_labels,pc_labels); % find stim labels that are also pc labels
is_response_pc = ismember(response_labels,pc_labels);

%% Build final CCEP network
final_stim_labels = stim_labels(is_stim_pc); % Remove stim labels that aren't pc labels
final_response_labels = response_labels(is_response_pc);
ccep = ccep(is_response_pc,is_stim_pc); % not symmetric.
% make nans zero
%ccep(isnan(ccep)) = 0;

%% Get pc network
pc = pout.car_pc;
pc_labels = pout.keep_labels;
is_ccep_stim_label = ismember(pc_labels,final_stim_labels);
is_ccep_response_label = ismember(pc_labels,final_response_labels);
pc = pc(is_ccep_response_label,is_ccep_stim_label); % remove pc labels that aren't in cceps network

%% Build symmetric network
symmetric_labels = intersect(final_stim_labels,final_response_labels);
symmetric_stim_idx = ismember(final_stim_labels,symmetric_labels);
symmetric_response_idx = ismember(final_response_labels,symmetric_labels);
symmetric_ccep = ccep(symmetric_response_idx,symmetric_stim_idx);
symmetric_pc = pc(symmetric_response_idx,symmetric_stim_idx);

if ~issymmetric(symmetric_pc)
    error('oh no');
end

if ~isequal(size(ccep),size(pc))
    error('oh no')
end

if do_symmetric
    pc = symmetric_pc;
    ccep = symmetric_ccep;
end

if do_binary == 1
    
    
    
    %% Turn matrices into binary versions
    all_cors = (pc(:));
    top_5 = prctile(all_cors,95);
    pc((pc)<top_5) = nan;

    % same for ccep
    ccep(ccep==0) = nan;
    
    % Degrees
    ns_response_chs = sum(~isnan(pc),2);
    ns_stim_chs = sum(~isnan(pc),1);
    outdegree = sum(~isnan(ccep),1);
    indegree = sum(~isnan(ccep),2)';
    
    
else

    %% Correlate outdegree and ns
    ns_response_chs = nansum(pc,2);
    ns_stim_chs = nansum(pc,1);
    outdegree = nansum(ccep,1);
    indegree = nansum(ccep,2)';
    

end

[rout,pou] = corr(ns_stim_chs',outdegree');
[rin,pin] = corr(ns_response_chs,indegree');

stats.out.r = rout;
stats.out.p = pou;
stats.out.n = length(outdegree);
stats.in.r = rin;
stats.in.p = pin;
stats.in.n = length(indegree);

%% funny business
all_rs = nan(size(ccep,1),1);
for r = 1:size(ccep,1)
    curr_r = corr(ccep(r,:)',pc(r,:)','rows','pairwise');
    all_rs(r) = curr_r;
end

if do_plots
    %% Make plots
    figure
    set(gcf,'position',[100 100 800 500])
    main_axis = tiledlayout(2,2,'TileSpacing','compact','padding','compact');

    %% Title
    if do_symmetric
        sym_text = '_sym';
    else
        sym_text = '_asym';
    end
    C = strsplit(out.name,'_');
    title(main_axis,C{1},'fontsize',20)


    nexttile
    if do_log
        plot_thing = log(ccep);
        %plot_thing(plot_thing = -inf) = 0;
    else
        plot_thing = ccep;
    end
    turn_nans_white_ccep(plot_thing)
    %title('CCEP')
    if show_labels
        if do_symmetric
            xticks(1:length(symmetric_labels))
            xticklabels(symmetric_labels)
            yticks(1:length(symmetric_labels))
            yticklabels(symmetric_labels)
        else
            xticks(1:length(final_stim_labels))
            xticklabels(final_stim_labels)
            yticks(1:length(final_response_labels))
            yticklabels(final_response_labels)
        end
    else
        xticklabels([])
        yticklabels([])
    end
    xlabel('Stim electrode')
    ylabel('Response electrode')
    c = colorbar;
    if do_log
        ylabel(c,'CCEP Z-score (log scale)','fontsize',15)
    else
        ylabel(c,'CCEP Z-score','fontsize',15)
    end
    set(gca,'fontsize',15)

    nexttile
    turn_nans_white_ccep(pc)
    %title('Resting PC')
    if show_labels
        if do_symmetric
            xticks(1:length(symmetric_labels))
            xticklabels(symmetric_labels)
            yticks(1:length(symmetric_labels))
            yticklabels(symmetric_labels)
        else
            xticks(1:length(final_stim_labels))
            xticklabels(final_stim_labels)
            yticks(1:length(final_response_labels))
            yticklabels(final_response_labels)
        end
    else
        xticklabels([])
        yticklabels([])
    end
    xlabel('Electrode')
    ylabel('Electrode')
    d = colorbar;
    ylabel(d,'Pearson correlation coefficient','fontsize',15);
    set(gca,'fontsize',15)

    if show_labels
        col = [1 1 1];
    else
        col = [0 0 0];
    end


    nexttile
    colororder({'k','k'})
    yyaxis left
    yticklabels([])
    yyaxis right
    plot(ns_stim_chs,outdegree,'o','color',col,'linewidth',2)
    if show_labels
        if do_symmetric
            text(ns_stim_chs,outdegree,symmetric_labels,'horizontalalignment','center')
        else
            text(ns_stim_chs,outdegree,final_stim_labels,'horizontalalignment','center')
        end
    end
    xlabel('PC node strength')
    ylabel('CCEP outdegree')
    set(gca,'fontsize',15)
    yl = ylim;xl = xlim;
    text(xl(2),yl(2),sprintf('r = %1.2f\np = %1.3f',rout,pou),...
        'VerticalAlignment','top','fontsize',15,'HorizontalAlignment','right')


    nexttile
    colororder({'k','k'})
    yyaxis left
    yticklabels([])
    yyaxis right
    plot(ns_response_chs,indegree,'o','color',col,'linewidth',2)
    if show_labels
        if do_symmetric
            text(ns_response_chs,indegree,symmetric_labels,'horizontalalignment','center')
        else
            text(ns_response_chs,indegree,final_response_labels,'horizontalalignment','center')
        end
    end
    xlabel('PC node strength')
    ylabel('CCEP indegree')
    set(gca,'fontsize',15)
    pause(0.3)
    xl = xlim; yl = ylim;
    text(xl(2),yl(2),sprintf('r = %1.2f\np = %1.3f',rin,pin),...
        'VerticalAlignment','top','fontsize',15,'HorizontalAlignment','right')


    %% Save
    if do_pretty
        out_dir = [results_folder,'fc_corr/'];
        if ~exist(out_dir,'dir')
            mkdir(out_dir);
        end
        print(gcf,[out_dir,C{1},sym_text],'-dpng');
    end


    if do_gui
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
        if do_symmetric
            stim_label = symmetric_labels{x}; response_label = symmetric_labels{y};
        else
            stim_label = final_stim_labels{x}; response_label = final_response_labels{y};
        end
        figure
        set(gcf,'position',[215 385 1226 413])
        show_avg(out,stim_label,response_label,0)

        pause
        close(gcf)
    end
    
    end
    
    close(gcf)

end

 
