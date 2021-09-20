%% prepare space
clear all; close all; clc;
%% load subject's results
subj = 'HUP218';
locations = cceps_files;
load([[locations.results_folder,'out_files/results_'],subj,'_CCEP.mat']);
savedir = fullfile(pwd,'resultsout_files/','waveform_review',subj);
mkdir(savedir);
%% get all CCEP average waveforms into concatenated data matrix
stim_electrodes = find(~isempty_c({out.elecs.arts}'));
all_cceps = horzcat(out.elecs(stim_electrodes).avg)';

%% make region index
%T = size(out.elecs(stim_electrodes(1)).avg,1); N = length(stim_electrodes);
%t_idx = repmat((1:T)',[N 1]);

%% exclude channgel
ch_retain = sum(isnan(all_cceps),2) == 0; % channels that respond to every CCEP ... should ideally not through out any channels but whatever
all_cceps = all_cceps(ch_retain,:);

[b,a] = butter(4, [30/(out.stim.fs/2), 200/(out.stim.fs/2)], 'stop');
all_cceps = filtfilt(b,a,all_cceps')'; % filtfilt prevents phase distortion

[coeff,scores,~,~,explained] = pca(all_cceps);
%% 
n_pcs = 20;
f=figure; 
subplot(1,4,1);
imagesc(all_cceps); 
sd = std(all_cceps,[],'all');
u = mean(all_cceps,'all');
caxis([u-2*sd u+2*sd]);
title('Data matrix');

subplot(1,4,2);
imagesc(coeff(:,1:n_pcs));
title('Coefficients')
xlabel('Channel');

subplot(1,4,3);
plot(coeff(:,1:4));
title('Scores Time Course');

subplot(1,4,4);
plot(cumsum(explained(1:n_pcs)),'b');
ylabel('Cumulative Variance Explained');
xlabel('Number of components');