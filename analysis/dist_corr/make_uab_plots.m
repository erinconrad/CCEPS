% make uab plots

locations = cceps_files;
data_folder = locations.data_folder;
results_folder = locations.results_folder;
uab_results_folder = [results_folder,'uab_results/'];
uab_data_folder = [data_folder,'UAB_CCEPS/'];

%% First, get distance correlations
% Loop through output files
listing = dir([uab_results_folder,'*.mat']);

corr_and_ci = nan(2,4);

figure
set(gcf,"Position",[10 10 700 500])
t=tiledlayout(2,2,'TileSpacing','tight','padding','tight');

stim_ch = 'LMC7';
response_ch = 'LAC8';

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
    matchedN1 = out.network(1).A(idx_ch,idx_ch);
    matchedN2 = out.network(2).A(idx_ch,idx_ch);

    if i ==2
        nexttile(t,1)
        matchedN1(matchedN1<4)=0;
        nan_rows = all(isnan(matchedN1),2);
        nan_columns = all(isnan(matchedN1),1);
        stim_chs = matchingChannels(~nan_columns);
        response_chs = matchingChannels(~nan_rows);
        imagesc(log(matchedN1(~nan_rows,~nan_columns)))
        hold on
        plot(find(strcmp(stim_chs,stim_ch)),...
            find(strcmp(response_chs,response_ch)),'s','markersize',20,...
            'linewidth',3,'Color','r')
        xticklabels([])
        yticklabels([])
        c = colorbar;
        ylabel(c,'N1 z-score (log)')
        xlabel('Stimulation site')
        ylabel('Recording site')
        set(gca,'fontsize',25)
        
        nexttile(t,2)
        
        curr_avg = out.elecs(strcmp(out.chLabels,stim_ch)).avg(:,...
            strcmp(out.chLabels,response_ch));
        fs = out.other.stim.fs;
        plot(linspace(-0.5,0.8,length(curr_avg)),curr_avg,'k','LineWidth',2)
        xlim([-0.5 0.8])
        xlabel('Time (s)')
        ylabel('\muV')
        set(gca,'fontsize',25)
        
        nexttile(t,3)
        plot(matchedDist(:),(matchedN1(:)),'o')
        rho = corr(matchedDist(:),matchedN1(:),'type','spearman','rows','pairwise');
        str = sprintf('\\rho = %1.2f',rho);
        annotation("textbox",[0.19 0.35 0.1 0.1],'String',['Pt 1 $' str '$'],...
            'linestyle','none','fontsize',25,'Interpreter', 'latex')
        xlabel('Distance (mm)')
        ylabel('N1 (z-score)')
        set(gca,'fontsize',25)
    elseif i == 1
        t4=nexttile(t,4);
        plot(matchedDist(:),(matchedN1(:)),'o')
        xlabel('Distance (mm)')
        ylabel('N1 (z-score)')
        set(gca,'fontsize',25)
        rho = corr(matchedDist(:),matchedN1(:),'type','spearman','rows','pairwise');
        str = sprintf('\\rho = %1.2f',rho);
        annotation("textbox",[0.75 0.35 0.1 0.1],'String',['Pt 2 $' str '$'],...
            'linestyle','none','fontsize',25,'Interpreter', 'latex')

    end

    
    %{
    if i == 2
        N1_plot = matchedN1;
        dist_plot = matchedDist;
        plot_out = out;
        chs_out = matchingChannels;
    end
    %}

    % prep data for bootstrap CIs
    %{
    which_chs = 1:size(matchedDist,1);
    ci = bootci(1e3,@(x) corr_boot(x,matchedN1,matchedDist),which_chs);
    mean_corr = corr(matchedDist(:),matchedN1(:),'type','spearman','rows','pairwise');
    corr_and_ci(i,1:3) = [mean_corr,ci'];
    corr_and_ci(i,4) = length(intersect(matchingChannels,out.chLabels(out.stim_chs))); % number of stim channels
    %}

end


annotation("textbox",[0 0.91 0.1 0.1],"String","A",'FontSize',30,'linestyle','none')
annotation("textbox",[0.57 0.91 0.1 0.1],"String","B",'FontSize',30,'linestyle','none')
annotation("textbox",[0 0.45 0.1 0.1],"String","C",'FontSize',30,'linestyle','none')
annotation("textbox",[0.57 0.45 0.1 0.1],"String","D",'FontSize',30,'linestyle','none')

set(gcf,'renderer','painters')

print(gcf,[uab_results_folder,'example_cceps'],'-dpng')
%{
nexttile
errorbar([1 2],corr_and_ci(:,1),corr_and_ci(:,1)-corr_and_ci(:,2),...
    corr_and_ci(:,3)-corr_and_ci(:,1),'ko','linewidth',2,'MarkerSize',10)
hold on
errorbar([2],corr_and_ci(2,1),corr_and_ci(2,1)-corr_and_ci(2,2),...
    corr_and_ci(2,3)-corr_and_ci(2,1),'ro','linewidth',2,'MarkerSize',10)
xlim([0.5 2.5])

plot(xlim,[0 0],'k--','LineWidth',2)
xticks([1 2])
xticklabels({'Pt 1','Pt 2'})
ylim([-1 1])
ylabel('N1-distance correlation (\rho)')
set(gca,'fontsize',25)
%}

function r = corr_boot(chs,matchedN1,matchedDist)
    dist_net = matchedDist(chs,chs);
    n1_net = matchedN1(chs,chs);
    r = corr(dist_net(:),n1_net(:),'type','spearman','rows','pairwise');

end