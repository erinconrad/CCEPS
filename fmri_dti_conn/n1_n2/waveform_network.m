clear all; clc;
addpath(genpath('.')); 
locations = cceps_files;

%% generate N1 and N2 networks

for subj = locations.subjects
    subj = char(subj); 
    fprintf([repmat('%',1,20),'\n','Computing networks for %s \n',repmat('%',1,20),'\n'],subj);  
    
    if ~exist([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)],'file'), continue; end
    
    load([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)]);
    if isfield(out,'A_waveform')
        out = rmfield(out,'A_waveform');
    end
    for waveform = {'N1','N2'}        
        out.A_waveform.(char(waveform)) = simple_build_network(out,char(waveform));
    end
    if ~isequaln(out.A,out.A_waveform.N1)
        error([subj,': not reproducing erin''s network construction'])
    end
    save([locations.results_folder,sprintf('out_files/results_%s_CCEP.mat',subj)],'out');    
end

