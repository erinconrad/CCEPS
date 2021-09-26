clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = fullfile(locations.results_folder,'parcellation'); mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
%% load atlas

atlas_img = niftiread(fullfile('../data','nifti','BN_Atlas_246_2mm.nii.gz'));

%% load SC
d = dir('../data/sc/BNA_SC_3D_246/*.nii.gz');
SC = nan(length(d));
for j = 1:length(d)
    fprintf('SC ROI %d\n',j)
    nii = niftiread(fullfile(d(j).folder,d(j).name));
    roi_conn = PARCELLATE_IMAGE(nii,atlas_img); % get sc for that ROI
    SC(j,:) = roi_conn;
end
SC = (SC + SC')/2; % symmetrize
SC(~~eye(length(d))) = nan;

%% load FC
d = dir('../data/fc/BNA_FC_3D_246/*.nii.gz');
FC = nan(length(d));
for j = 1:length(d)
    fprintf('FC ROI %d\n',j)
    nii = niftiread(fullfile(d(j).folder,d(j).name));
    roi_conn = PARCELLATE_IMAGE(nii,atlas_img); % get sc for that ROI
    FC(j,:) = roi_conn;
end
FC = (FC + FC')/2; % symmetrize
FC(~~eye(length(d))) = nan;

%% save
save(fullfile(savedir,'BrainnetomeSCFC.mat'),'SC','FC');