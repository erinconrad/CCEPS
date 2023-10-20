%% description
%{
This makes a plot of a pretty ccep

%}

ccep_file = 'results_HUP230_CCEP.mat';
stim = 'LA6';
response = 'LB4';

% load the thing
load(ccep_file);

% get channel nums
stimn = find(strcmp(out.chLabels,stim));
responsen = find(strcmp(out.chLabels,response));

% get waveform
wave = out.elecs(stimn).avg(:,responsen);

% plot the waveform
figure
plot(wave,'k','linewidth',3)
axis off

% print
print(gcf,'ccep','-depsc')