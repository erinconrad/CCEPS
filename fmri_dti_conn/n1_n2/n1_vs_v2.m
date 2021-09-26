clear all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'N1_N2'); mkdir(savedir);
%% generate N1 and N2 networks

for subj = locations.subjects
    subj = char(subj); 
    fprintf([repmat('%',1,20),'\n','Comparing N1 and N2 networks for %s \n',repmat('%',1,20),'\n'],subj); 
    
    if ~exist([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)],'file'), continue; end

    
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    
    N1 = log(out.A_waveform.N1); N2 = log(out.A_waveform.N2);   
    
    f=figure('Name',subj);
    %{
    subplot(2,2,1);
    imagesc(N1); axis square; colorbar; %('southoutside');
    title('N1')
    subplot(2,2,2);
    imagesc(N2); axis square; colorbar; %('southoutside');
    title('N2')
    subplot(2,2,3);
    sel_cons = ~isnan(N1) & ~isnan(N2);
    D = squareform(pdist(out.locs_bipolar));
    plot(D(sel_cons).^-1,N2(sel_cons),'.');   
    xlabel('Distance^{-1}'); ylabel('N2 Amplitude');
    [r,p] = corr(N1(sel_cons),N2(sel_cons),'type','pearson','rows','complete');
    title(['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]);    
    subplot(2,2,4);
    plot(N1(sel_cons),N2(sel_cons),'.')
    xlabel('N1'); ylabel('N2');
    [r,p] = corr(N1(sel_cons),N2(sel_cons),'type','pearson','rows','complete');
    title({'N1 vs. N2 when both present',['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]});
    f=FIGURE_SIZE_CM(f,18,12);
    saveas(f,fullfile(savedir,['N2vsN1Distance_',subj,'.pdf']));
    %}
    sel_cons = ~isnan(N1) & ~isnan(N2);
    plot(N1(sel_cons),N2(sel_cons),'.')
    xlabel('log(N1)'); ylabel('log(N2)');
    [r,p] = corr(N1(sel_cons),N2(sel_cons),'type','spearman','rows','complete');
    title({'N1 vs. N2 when both present',['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]});
    f=FIGURE_SIZE_CM(f,6,6);
    saveas(f,fullfile(savedir,['N1vsN2_',subj,'.pdf']));
    
    % plot N1 as a predictor of N2
    %
    %if sum(~isnan(N1),[1 2]) >0 & sum(~isnan(N2),[1 2]) >0
        f=figure;
        subplot(1,2,1);
        auc = plot_roc(reshape(~isnan(N2(~isnan(N1))),[],1),reshape(N1(~isnan(N1)),[],1),1);
        title({'N1 amp -> N2 presence',['AUC: ',LABELROUND2(auc)]});
        axis square;
        subplot(1,2,2);
        auc = plot_roc(reshape(~isnan(N1(~isnan(N2))),[],1),reshape(N2(~isnan(N2)),[],1),1);
        title({'N2 amp -> N1 presence',['AUC: ',LABELROUND2(auc)]});
        axis square;
        f=FIGURE_SIZE_CM(f,12,7);
        saveas(f,fullfile(savedir,['N1vsN2ROC_',subj,'.pdf']));
    %end
    %}
end