function [CCEPsParcellated,allElectrodesROIAssignments,electrodesInsideThreshold] = CCEPS_TO_PARCELS_MNI(ElectrodeMNICoords,CCEPS,nifti,hemi_idx,dist_thresh)

% By Eli Cornblath, August 13, 2021
% this function is adopted from a function I wrote called
% PROBES_TO_PARCELS_MNI designed to parcellate gene expression electrodes
%
% INPUTS:
% 
% ElectrodeMNICoords: nElecs x 3 array, where nElecs is number of electrodes 
% in CCEPs network. columns are x y z coordinates in MNI space
% 
% CCEPs: nElecs x nElecs network of CCEPs
% 
% nifti: nifti struct as loaded by freesurfer matlab load_nifti function.
% nifti should define a parcellation
% 
% hemi_idx: vector of indices selecting hemisphere of interest. search for
% sample-to-ROI assignment will be limited to these regions, so no chance
% of assigning sample to incorrect hemisphere.
% 
% dist_thresh: allowed distance from sample location to edge of parcel. 3 mm used
% in rick's paper https://www.nature.com/articles/s41551-019-0404-5
% 
% OUTPUTS:
% 
% CCEPsParcellated: nparc x nparc CCEPs network, where nparc is number of ROIs in
% parcellation
% allElectrodesROIAssignments: index of parcel assignment for each electrode
% electrodesInsideThreshold: vector of electrode indices assigned to any parcel
% 
% NOTES:
% this function only tested on Schaefer parcellations thus far. 2/15/21

%% convert MNI coordinates to lausanne array coordinates by applying affine

% using function from https://www.nitrc.org/projects/mni2orfromxyz/
[ElectrodeArrayCoords(:,1),ElectrodeArrayCoords(:,2),ElectrodeArrayCoords(:,3)] = ...
    mni2orFROMxyz(ElectrodeMNICoords(:,1),...
    ElectrodeMNICoords(:,2), ElectrodeMNICoords(:,3),nifti.pixdim(2),'mni');

%% assign each cortical probe to an ROI -- Aurina's method
img = nifti.vol;
nparc = length(unique(img))-1; % count parcels, -1 to account for 0 voxels which belong to no parcel
nElecs = size(ElectrodeArrayCoords,1);
if ~exist('dist_thresh','var')
    dist_thresh = 3; % distance threshold in mm for how close a probe must be to ROI to be assigned
end
dist_thresh = floor(dist_thresh / nifti.pixdim(2)); % convert distance threshold to number of voxels
disp(['Assigning electrodes to ROIs with a distance threshold of ',num2str(dist_thresh),' voxel(s)']);

% get array coordinates of non-zero voxels in cortical hemisphere of interest
[Coordx,Coordy,Coordz] = ind2sub(size(img),find(ismember(img, hemi_idx)));
nonzeroHemiArrayCoords = cat(2,Coordx,Coordy,Coordz);

%% assign cortical electrodes to ROIs in array space
% find nearest point in cortex of hemisphere of interest to each sample coordinate
k = dsearchn(nonzeroHemiArrayCoords,ElectrodeArrayCoords);
% extract coordinates of closest non-zero voxel in cortex of hemisphere of interest for each sample
allElectrodesClosestNonZeroCoord = nonzeroHemiArrayCoords(k,:);
allElectrodesClosestCoordDistance = diag(pdist2(allElectrodesClosestNonZeroCoord,ElectrodeArrayCoords));
% find electrodes that are inside the distance threshold around their closest nz coord
electrodesInsideThreshold = find(allElectrodesClosestCoordDistance <= dist_thresh);

%{
niftiValue = nan(size(ElectrodeArrayCoords,1),1);
for j=1:size(ElectrodeArrayCoords,1)
    if ~isnan(ElectrodeArrayCoords(j,1))
        niftiValue(j) = img(round(ElectrodeArrayCoords(j,1)),round(ElectrodeArrayCoords(j,2)),...
            round(ElectrodeArrayCoords(j,3)));
    end
end
niftiValue = [niftiValue allElectrodesClosestCoordDistance];
%}

allElectrodesROIAssignments = nan(nElecs,1);
for sample = electrodesInsideThreshold'
    allElectrodesROIAssignments(sample) = ...
        img(allElectrodesClosestNonZeroCoord(sample,1),...
        allElectrodesClosestNonZeroCoord(sample,2),...
        allElectrodesClosestNonZeroCoord(sample,3));
end

% see parc_test.m : it doesn't matter whether you average columns first or rows
CCEPsParcellated_tmp = nan(nparc,nElecs);
CCEPsParcellated = nan(nparc);
allROIElectrodeAssignments = cell(nparc,1);
for ROI = 1:nparc
    allROIElectrodeAssignments{ROI} = find(allElectrodesROIAssignments == ROI);
    if ~isempty(allROIElectrodeAssignments{ROI}) % if there are electrodes in an ROI
        % assign mean expression across those electrodes to the corresponding ROI
        % average over rows
        CCEPsParcellated_tmp(ROI,:) = ...
            nanmean(CCEPS(allROIElectrodeAssignments{ROI},:),1);
    end
end

for ROI = 1:nparc
    if ~isempty(allROIElectrodeAssignments{ROI}) % if there are electrodes in an ROI
        % then average over columns.
        CCEPsParcellated(:,ROI) = ...
            nanmean(CCEPsParcellated_tmp(:,allROIElectrodeAssignments{ROI}),2);
    end
end


disp(['Assigned ',num2str(length(electrodesInsideThreshold)),' out of ',num2str(nElecs),' cortical electrodes to ROIs']);
