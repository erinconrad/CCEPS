%% Structure-function coupling analysis

%% Info
%{
Available pts:
RID 652  HUP214 -> bad CCEPs
RID 656  HUP220 -> good CCEPs, soz LC2, LC3
RID 658  HUP216 -> bad CCEPs
RID 785  HUP223 -> good CCEPs, soz LB3, LC3
RID 860  HUP242 -> good CCEPs; electrode names in the sc file appear to be
wrong. These include RM but there is no RM in natus; excludes RQ, which is
in Natus
%}
clear
close all


%% RIDs
rids = [656,785];
sozs = {{'LC2','LC3'};{'LB3','LC3'}};

%% Point to data
sc_path = '../data/erin_IEEGsc/';
fc_path = '../data/cceps_files/';
out_path = '../Figures/';

%% Point to tools
addpath(genpath('../tools/'))

% Loop through rids
for i = 1%:length(rids)

    r = rids(i);
    curr_sozs = sozs{i};

    % Load the ccep file
    ccep_path = [fc_path,'sub-RID0',sprintf('%d',r),'/'];
    listing = dir([ccep_path,'*.mat']);
    ccep = load([ccep_path,listing.name]);
    ccep = ccep.out;

    % Get ccep networks
    n1 = ccep.network(1).A0;
    n2 = ccep.network(2).A0;
    bipolar_labels = ccep.bipolar_labels;
    ccep_labels = ccep.chLabels;

    % assign n1s and n2s > threshold to be nans, suspect artifact
    n1(n1>30) = nan;
    n2(n2>30) = nan;

    % Load the SC file
    struc_path = [sc_path,'sub-RID0',sprintf('%d',r),'/'];
    listing = dir([struc_path,'connectivity_5mmSph.mat']); % 5 mm
    sc = load([struc_path,listing.name]);
    sc_labels = sc.electrodes.labels;

    % Reorder the ccep stuff to match the SC stuff
    ccep_order = nan(length(sc_labels),1);
    for j = 1:length(sc_labels)
        % Find the ccep label that matches
        ccep_order(j) = find(strcmp(ccep_labels,sc_labels{j}));
    end
    assert(isequal(sc_labels,ccep_labels(ccep_order)))

    % Realign n1 and n2
    n1 = n1(ccep_order,ccep_order);
    n2 = n2(ccep_order,ccep_order);

     % get a distance matrix
    locs = [sc.electrodes.mm_x sc.electrodes.mm_y sc.electrodes.mm_z];
    dist = nan(size(locs,1),size(locs,1));
    for j = 1:size(locs,1)
        for k = 1:size(locs,1)
            dist(j,k) = vecnorm(locs(j,:)-locs(k,:));
        end
    end

    % Add this to the connectivity structure
    sc.connectivity.dist = dist;

    % Get sc types
    sc_types = fieldnames(sc.connectivity);
   
    % Show some correlations
    if 0
    figure
    set(gcf,'position',[-600 1274 1870 567])
    t = tiledlayout(2,length(sc_types));
    for k = 1:2
        if k == 1
            curr_ccep = n1;
            ccep_name = 'N1';
            
        else
            curr_ccep = n2;
            ccep_name = 'N2';
        end

        % make 0s nans
        curr_ccep(curr_ccep==0) = nan;

        for j = 1:length(sc_types)
            curr_sc = sc.connectivity.(sc_types{j});

            % Make 0s nans
            curr_sc(curr_sc==0) = nan;
    
            nexttile
            plot(curr_sc(:),curr_ccep(:),'o')
            [cr,p] = corr(curr_sc(:),curr_ccep(:),'rows','pairwise','type','spearman');
            
            title(sprintf('r = %1.2f, p = %1.3f',cr,p))
            xlabel(sc_types{j})
            ylabel(ccep_name)
            set(gca,'fontsize',15)
    
        end
    end
    title(t,sprintf('RID %d',r))
    end

    % Loop over n1 and n2
    if 0
    figure
    set(gcf,'position',[37 278 1332 519])
    tiledlayout(2,3,'tilespacing','tight','padding','tight')
    for in = 1:2

        if in == 1
            curr_ccep = n1;
            ccep_name = 'N1';
        else
            curr_ccep = n2;
            ccep_name = 'N2';
        end

        %% Reproduce Nishant eFig 3 - are cceps higher for contact pairs that are structurally connected?
        count = sc.connectivity.count;
        count_vec = count(:);
        connected = count_vec > 0;
        conn_text = cell(length(connected),1);
        conn_text(connected) = {'Connected'};
        conn_text(~connected) = {'Not connected'};
        ccep_vec = curr_ccep(:);
    
        
        nexttile
        boxplot(ccep_vec,conn_text) % replace with something that shows dots
        p1 = ranksum(ccep_vec(connected),ccep_vec(~connected));
        ylabel(ccep_name)
        hold on
        yl = ylim;
        ylnew = [yl(1) yl(1) + 1.3*(yl(2)-yl(1))];
        ylim(ylnew)
        ybar = yl(1) + 1.1*(yl(2)-yl(1));
        ytext = yl(1) + 1.15*(yl(2)-yl(1));
        plot([1 2],[ybar ybar],'k','linewidth',2)
        if p1 < 0.001
            text(1.5,ytext,'***','fontsize',15)
        end
        set(gca,'fontsize',15)
          
    
       %% Now show SC-FC coupling
       nexttile
       % get the non-zero connections
       non_zero_ccep_vec = ccep_vec;
       non_zero_count_vec = count_vec;
       non_zero_ccep_vec(non_zero_ccep_vec==0 | non_zero_count_vec==0) = nan;
       non_zero_count_vec(non_zero_count_vec==0 | non_zero_ccep_vec==0) = nan;

       plot(non_zero_ccep_vec,non_zero_count_vec,'o')
       xlabel(ccep_name)
       ylabel('Structural connectivity')
       [r,p2] = corr(non_zero_ccep_vec,non_zero_count_vec,'rows','pairwise','type','spearman');
       title(sprintf('rho = %1.2f, p = %1.3f',r,p2))
       set(gca,'fontsize',15)

       %% Do the virtual resection approach
       nchs = size(count,1);
       rho_changes = nan(nchs,1);
       for ich = 1:nchs
            temp_count = count;
            temp_ccep = curr_ccep;

            % Lesion the current channel
            temp_count(ich,:) = []; temp_count(:,ich) = [];
            temp_ccep(ich,:) = []; temp_ccep(:,ich) = [];

            % re-vectorize, remove 0s
            temp_count = temp_count(:);
            temp_ccep = temp_ccep(:);
            temp_count(temp_count == 0 | temp_ccep == 0) = nan;
            temp_ccep(temp_ccep == 0 | temp_count == 0) = nan;

            % recalculate rho
            rho_new = corr(temp_count,temp_ccep,'rows','pairwise','type','spearman');
            rho_changes(ich) = (rho_new - r)/r;

       end

       % plot sorted changes
       [rho_changes_sorted,I] = sort(rho_changes);
       ch_labels_sorted = sc_labels(I);
       is_soz = ismember(ch_labels_sorted,curr_sozs);
       soz_channels = find(is_soz);
       not_soz_channels = find(~is_soz);
       
       
       nexttile
       stem(not_soz_channels,rho_changes_sorted(~is_soz))
       hold on
       stem(soz_channels,rho_changes_sorted(is_soz),'linewidth',2)
       xticklabels([])
       legend({'Not SOZ','SOZ'})
       xlabel('Channel')
       ylabel('Rho change with resection')
       set(gca,'fontsize',15)
       %xticks(1:nchs)
       %xticklabels(ch_labels_sorted)

       % Plot the rho_changes on the electrode locs
       %{
       nexttile
       is_soz = ismember(sc_labels,curr_sozs);
       scatter3(locs(is_soz,1),locs(is_soz,2),locs(is_soz,3),100,rho_changes(is_soz),'filled','p')
       hold on
       scatter3(locs(~is_soz,1),locs(~is_soz,2),locs(~is_soz,3),100,rho_changes(~is_soz),'filled','o')
       biggest_val = max(abs(rho_changes));
       colorbarpzn(-biggest_val,biggest_val)
       
       hold on
       text(locs(:,1),locs(:,2),locs(:,3),sc_labels)
       %}

    end
    end


    %% For grant, do just N1 and do subset of analyses
    curr_ccep = n1;
    ccep_vec = curr_ccep(:);

    if 1
    figure
    set(gcf,'position',[0 0 1450 435])
    tiledlayout(1,3,'TileSpacing','tight','padding','tight')
    % First, correlation with distance
    dist = sc.connectivity.dist;
    dist_vec = dist(:);
    dist_vec(dist_vec == 0) = nan;
    nexttile
    plot(dist_vec,ccep_vec,'o')
    hold on
    xlabel('Distance (mm)')
    ylabel('N1 amplitude')
    set(gca,'fontsize',30)

    % fit a rat11 model
    any_nan = any([isnan(dist_vec),isnan(ccep_vec)],2);
    dist_vec_no_nan = dist_vec; 
    dist_vec_no_nan(any_nan) = [];
    ccep_vec_no_nan = ccep_vec;
    ccep_vec_no_nan(any_nan) = [];
    f = fit(dist_vec_no_nan,ccep_vec_no_nan,'rat11','startpoint',[0.1 0.1 0.1]);
    x = [0:1:max(dist_vec)];
    temp_y = (f.p1 * x + f.p2)./(x + f.q1);
    plot(x,temp_y,'linewidth',3);


    % Now, connected vs unconnnected
    count = sc.connectivity.count;
    count_vec = count(:);
    connected = count_vec > 0;
    conn_text = cell(length(connected),1);
    conn_text(connected) = {'Connected'};
    conn_text(~connected) = {'Not connected'};
    
    nexttile
    %violin([{ccep_vec(connected)},{ccep_vec(~connected)}])
    bh = boxplot(ccep_vec,conn_text);
    set(bh,'linewidth',2);
    p1 = ranksum(ccep_vec(connected),ccep_vec(~connected));
    ylabel('N1 amplitude')
    hold on
    yl = ylim;
    ylnew = [yl(1) yl(1) + 1.11*(yl(2)-yl(1))];
    ylim(ylnew)
    ybar = yl(1) + 1.03*(yl(2)-yl(1));
    ytext = yl(1) + 1.05*(yl(2)-yl(1));
    plot([1 2],[ybar ybar],'k','linewidth',2)
    if p1 < 0.001
        text(1.5,ytext,'***','fontsize',30,'HorizontalAlignment','center')
    end
    %xticks([1 2])
    %xticklabels({'Connected','Not\nconnected'})
    set(gca,'fontsize',26)


    % Now correlation with SC
    nexttile
   % get the non-zero connections
   non_zero_ccep_vec = ccep_vec;
   non_zero_count_vec = count_vec;
   non_zero_ccep_vec(non_zero_ccep_vec==0 | non_zero_count_vec==0) = nan;
   non_zero_count_vec(non_zero_count_vec==0 | non_zero_ccep_vec==0) = nan;

   plot(non_zero_count_vec,non_zero_ccep_vec,'o')
   ylabel('N1 amplitude')
   xlabel('Tract count')
   [r,p2] = corr(non_zero_ccep_vec,non_zero_count_vec,'rows','pairwise','type','spearman');
   %title(sprintf('rho = %1.2f',r,p2))
   set(gca,'fontsize',30)
   any_nan = any([isnan(non_zero_count_vec),isnan(non_zero_ccep_vec)],2);
   ccep_no_nan = non_zero_ccep_vec;
   count_no_nan = non_zero_count_vec;
   ccep_no_nan(any_nan) = [];
   count_no_nan(any_nan) = [];
   p = polyfit(count_no_nan,ccep_no_nan,1);
   x1 = linspace(0,max(non_zero_count_vec));
   y1 = polyval(p,x1);
   hold on
   plot(x1,y1,'linewidth',3)
   text(3.3e4,24,['\rho',sprintf(' = %1.2f',r)],'fontsize',30)
   
   annotation('textbox',[0 0.9 0.1 0.1],'String','A','fontsize',30,'LineStyle','none')
   annotation('textbox',[0.33 0.9 0.1 0.1],'String','B','fontsize',30,'LineStyle','none')
   annotation('textbox',[0.67 0.9 0.1 0.1],'String','C','fontsize',30,'LineStyle','none')
   print(gcf,[out_path,'sfc'],'-dpng')
    
   end



end
