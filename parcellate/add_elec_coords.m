clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
for subj = locations.subjects
    subj = char(subj); fprintf('Adding coordinates to %s\n',subj);
    
    if ~exist([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)],'file')
        continue
    end
    
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    coords = load('../data/elecs.mat');
    
    %% get coordinates of each monopolar electrode and bipolar pair
    out = ADD_COORDINATES(out,coords);
    out.locs_bipolar = BIPOLAR_MONTAGE_COORDS(out.locs_monopolar,out.chLabels);
    save(sprintf('../results/out_files/results_%s_CCEP.mat',subj),'out');
end