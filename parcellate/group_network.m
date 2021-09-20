clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'parcellation'); mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
%% load data

atlas_table = atlas_def;

all_subjects = locations.subjects;
nsubjs = length(all_subjects);
for wave = {'N1','N2'}
    wave = char(wave);
    for j = 1:nsubjs
        subj = char(all_subjects(j));
        
        if ~exist([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)],'file'),continue;end

        
        load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
        all_data(j) = out.parcellation.(wave);
    end
    %% make group network
    for atlas = 1:size(atlas_table,1)
        atlas_short_name = char(atlas_table.atlas_short_name(atlas));
        atlas_file_name = char(atlas_table.atlas_file_name(atlas));
        nifti_path = fullfile('../data','nifti',[atlas_file_name,'.nii.gz']);
        nifti = load_nifti(nifti_path);
        D = ATLAS_DMAT(nifti.vol);
        A_ind = cat(3,all_data.(atlas_short_name)); % get A matrices in atlas space for each patient        
        A = nanmean(A_ind,3);
        A(~~eye(length(A))) = nan; % ensure diag is still nan even after averaging
        save(fullfile(savedir,sprintf('%s_GroupNetwork_%s.mat',wave,atlas_short_name)),'A','D','A_ind','all_subjects');
    end
end