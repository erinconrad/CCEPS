clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'distance_atlasspace'); mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
%% load group network

atlas_table = atlas_def;
SC = load('../data/sc/SC/
for atlas = 1:size(atlas_table,1)
    atlas_short_name = char(atlas_table.atlas_short_name(atlas));
    atlas_file_name = char(atlas_table.atlas_file_name(atlas));
    nifti_path = fullfile('../data','nifti',[atlas_file_name,'.nii.gz']);
    nifti = load_nifti(nifti_path);
    load(fullfile(locations.results_folder,'parcellation',sprintf('GroupNetwork_%s.mat',atlas_short_name)),'A','D');
    
%% plot    

    f=figure;
    subplot(1,3,1);
    A = log(A);
    imagesc(A); axis square; colorbar('southoutside'); title(['CCEPS: ',atlas_short_name],'Interpreter','none');
    subplot(1,3,2); 
    imagesc(D); axis square; colorbar('southoutside'); title(['Distance Matrix: ',atlas_short_name],'Interpreter','none');
    subplot(1,3,3); 
    sel_cons = ~isnan(A) & ~eye(length(A)); % select connections that exist
    plot(D(sel_cons).^-1,A(sel_cons),'.'); axis square; colorbar('southoutside')
    [r,p] = corr(D(sel_cons).^-1,A(sel_cons),'type','spearman','rows','complete');
    title(['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]);
    xlabel('Distance^{-1}'); ylabel('log(CCEP)');
    f=FIGURE_SIZE_CM(f,18,9);
    saveas(f,fullfile(savedir,['CCEPSDistanceConnectivityAtlasSpace_',atlas_short_name,'.pdf']));

    
end

%%