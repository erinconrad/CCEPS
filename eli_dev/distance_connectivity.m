clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'distance_electrodespace'); mkdir(savedir);

for subj = locations.subjects
    
    subj = char(subj); fprintf('Plotting CCEPs vs. interelectrode distance for %s\n',subj);
    
    if ~exist([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)],'file'), continue; end

    
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    
    %% plot distance vs. CCEPs
    coords = out.locs_bipolar;
    D = squareform(pdist(coords)); % i'm not sure what resulting units of this are... i assume mm
    for wave = {'N1','N2'}
        wave = char(wave);
        A = out.A_waveform.(wave);
        A = log(A);
        %imagesc(D);
        f=figure; 
        subplot(1,3,1);
        imagesc(A); colorbar; axis square; title(['CCEPs: log(',wave,')']);
        xlabel('Stim'); ylabel('Record');
        prettifyEJC;
        subplot(1,3,2);
        imagesc(D); colorbar; axis square; title('Distance')
        xlabel('Electrode'); ylabel('Electrode');
        prettifyEJC;

        subplot(1,3,3);
        plot(OFFDIAG_VEC(D).^-1,OFFDIAG_VEC(A),'.'); xlabel('Distance^{-1}'); ylabel(sprintf('log(%s)',wave));
        [r,p] = corr(OFFDIAG_VEC(D).^-1,OFFDIAG_VEC(A),'type','spearman','rows','complete');
        title(['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]);
        prettifyEJC;

        %{
        subplot(2,2,4);
        plot(TRIL_VEC(D).^-1,TRIL_VEC(A),'.'); xlabel('$\frac{1}{Distance}$','Interpreter','latex'); ylabel('CCEP Lower tri');
        [r,p] = corr(TRIL_VEC(D).^-1,TRIL_VEC(A),'type','pearson','rows','complete');
        title(['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]);
        prettifyEJC;
        %}

        f=FIGURE_SIZE_CM(f,18,4);
        saveas(f,fullfile(savedir,[wave,'_DistanceConnectivity_',subj,'.pdf']))
        %% plot CCEPs degree:
        % holding these plots until i can put them on a brain
        %{
        f=figure;
        subplot(1,2,1);
        scatter3(coords(:,1),coords(:,2),coords(:,3),100,nansum(out.A,1),'filled');
        xlabel('x'); ylabel('y'); zlabel('z');
        axis square;
        colorbar('southoutside'); title('Out-Degree');
        prettifyEJC;

        subplot(1,2,2);
        scatter3(coords(:,1),coords(:,2),coords(:,3),100,nansum(out.A,2),'filled');
        xlabel('x'); ylabel('y'); zlabel('z');
        axis square;
        colorbar('southoutside'); title('In-Degree');
        prettifyEJC;
        f=FIGURE_SIZE_CM(f,18,9);
        saveas(f,fullfile(savedir,['CCEPsDegreeElectrodeSpace_',subj,'.pdf']))
        %}
    end
end