clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'distance_atlasspace'); mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
%% load group network

atlas_table = atlas_def;

for wave = {'N1','N2'}
    wave = char(wave);
    for atlas = 1:size(atlas_table,1)
        atlas_short_name = char(atlas_table.atlas_short_name(atlas));
        load(fullfile(locations.results_folder,'parcellation',sprintf('%s_GroupNetwork_%s.mat',wave,atlas_short_name)),'A','D');

    %% plot    

        f=figure;
        subplot(1,3,1);
        A = log(A);
        imagesc(A); axis square; colorbar('southoutside'); title({wave,atlas_short_name},'Interpreter','none');
        subplot(1,3,2); 
        imagesc(D); axis square; colorbar('southoutside'); title({'Distance Matrix:',atlas_short_name},'Interpreter','none');
        subplot(1,3,3); 
        sel_cons = ~isnan(A) & ~eye(length(A)); % select connections that exist
        plot(D(sel_cons).^-1,A(sel_cons),'.'); axis square; colorbar('southoutside')
        [r,p] = corr(D(sel_cons).^-1,A(sel_cons),'type','spearman','rows','complete');
        title(['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]);
        xlabel('Distance^{-1}'); ylabel(sprintf('log(%s)',wave));
        f=FIGURE_SIZE_CM(f,18,9);
        saveas(f,fullfile(savedir,[wave,'_DistanceConnectivityAtlasSpace_',atlas_short_name,'.pdf']));


    end
end
%%