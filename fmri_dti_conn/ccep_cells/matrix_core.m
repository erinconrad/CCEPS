clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'parcellation'); mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
%% load data

atlas_table = atlas_def;

nsubjs = length(locations.subjects);
for j = 1:nsubjs
    subj = char(locations.subjects(j));
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    all_data(j) = out.parcellation.A;
end
%% make group network
for atlas = 1:size(atlas_table,1)
    atlas_short_name = char(atlas_table.atlas_short_name(atlas));
    atlas_file_name = char(atlas_table.atlas_file_name(atlas));
    nifti_path = fullfile('../data','nifti',[atlas_file_name,'.nii.gz']);
    nifti = load_nifti(nifti_path);
    D = ATLAS_DMAT(nifti.vol);
    A = nanmean(cat(3,all_data.(atlas_short_name)),3);
    save(fullfile(savedir,sprintf('GroupNetwork_%s.mat',atlas_short_name),'A','D'));
end
%% load maps of interest
%{
matrix_core = load_nifti(fullfile('../data','nifti','calb_minus_pvalb.nii'));
matrix_core_parc = PARCELLATE_IMAGE(matrix_core.vol,nifti.vol);
%}
%%
f=figure;
subplot(1,3,1); 
imagesc(A); axis square; colorbar('southoutside'); title(['CCEPS: ',atlas_short_name],'Interpreter','none');
subplot(1,3,2); 
imagesc(D); axis square; colorbar('southoutside'); title(['Distance Matrix: ',atlas_short_name],'Interpreter','none');
subplot(1,3,3); 
sel_cons = ~isnan(A) & ~eye(length(A)); % select connections that exist
plot(D(sel_cons).^-1,A(sel_cons),'.'); axis square; colorbar('southoutside')
[r,p] = corr(D(sel_cons).^-1,A(sel_cons),'type','pearson','rows','complete');
title(['r = ',LABELROUND2(r),', p = ',LABELROUND2(p)]);
xlabel('Distance^{-1}'); ylabel('CCEP');
f=FIGURE_SIZE_CM(f,18,9);
saveas(f,fullfile(savedir,['CCEPSDistanceConnectivityAtlasSpace_',atlas_short_name,'.pdf']));
