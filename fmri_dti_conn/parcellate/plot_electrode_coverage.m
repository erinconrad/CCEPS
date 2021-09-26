clear all; close all; clc;
addpath(genpath('.')); 
locations = cceps_files;
load_dir = fullfile(locations.results_folder,'parcellation'); mkdir(load_dir);
savedir = fullfile(locations.results_folder,'electrode_coverage'); mkdir(savedir);
addpath(genpath(locations.freesurfer_matlab));
%% load data

atlas_table = atlas_def;

all_subjects = locations.subjects;
nsubjs = length(all_subjects);
atlas = 1;

for wave = {'N1','N2'}
    wave = char(wave);    
    atlas_short_name = char(atlas_table.atlas_short_name(atlas));
    load(fullfile(load_dir,sprintf('%s_GroupNetwork_%s.mat',wave,atlas_short_name)));
    
    surfplot_fname = fullfile(savedir,[wave,atlas_short_name,'GroupElectrodeCoverage.mat']);
    nodeData = nansum(A,2)~=0;
    plotTitles = {'Electrode Coverage'};
    save(surfplot_fname,'nodeData','plotTitles');
    
    system(['source ~/.bash_profile; source activate mayavi ; ',...
        'python eli/visualize/brainvis_ccep.py ',atlas_short_name,' ',...
        surfplot_fname]);  
    delete(surfplot_fname);
    
end

