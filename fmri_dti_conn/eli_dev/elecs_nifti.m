clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
savedir = [locations.results_folder,'out_files/parcellation/']; mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
addpath(genpath('~/Dropbox/Toolboxes/NifTI_20140122'));
%% load data

atlas_table = atlas_def;

atlas = 1;
atlas_short_name = char(atlas_table.atlas_short_name(atlas));
atlas_file_name = char(atlas_table.atlas_file_name(atlas));
nifti_path = fullfile('../data','nifti',[atlas_file_name,'.nii.gz']);

%% plot all electrodes on nifti
nsubjs = length(locations.subjects);
for j = 1:nsubjs
    subj = char(locations.subjects(j));
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    atlas_nii = load_nii(nifti_path);
    nii_max = max(atlas_nii.img,[],[1 2 3]);
    ElectrodeArrayCoords = nan(size(out.locs_bipolar));
    [ElectrodeArrayCoords(:,1),ElectrodeArrayCoords(:,2),ElectrodeArrayCoords(:,3)] = ...
        mni2orFROMxyz(out.locs_bipolar(:,1),...
        out.locs_bipolar(:,2), out.locs_bipolar(:,3),atlas_nii.hdr.dime.pixdim(2),'mni');
    excludeElecs = ~isnan(ElectrodeArrayCoords(:,1)) & sum(sign(ElectrodeArrayCoords),2)==3; % remove nans and negative array indices
    ElectrodeArrayCoords = round(ElectrodeArrayCoords(excludeElecs,:));
    for elec = 1:size(ElectrodeArrayCoords,1)
        atlas_nii.img(ElectrodeArrayCoords(elec,1),ElectrodeArrayCoords(elec,2),ElectrodeArrayCoords(elec,3))...
            = ceil(nii_max*1.1); % make electrodes stick out on nifti
    end
    if subj == 'HUP212'
        view_nii(atlas_nii); set(gcf,'Name',subj);
    end
end
%% visualize electrode coverage in atlas space

nsubjs = length(locations.subjects);
for j = 1:nsubjs
    subj = char(locations.subjects(j));
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    all_data(j) = out.parcellation.A;
end

A_all = nanmean(cat(3,all_data.(atlas_short_name)),3);
atlas_nii = load_nii(nifti_path);
unassignedParcels = ismember(atlas_nii.img,find(nansum(A_all,1)==0));
assignedParcels = ismember(atlas_nii.img,find(nansum(A_all,1)>0));
atlas_nii.img(unassignedParcels) = 1;
atlas_nii.img(assignedParcels) = 2;
%view_nii(x);
view_nii(atlas_nii);