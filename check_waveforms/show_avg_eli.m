function show_avg_eli(out,ich,jch)

plot_title = 0;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

%% Unpack out struct
elecs = out.elecs;
stim = out.stim;
fs = out.stim.fs;
chLabels = out.chLabels;
C = strsplit(out.name,'_');
name_first = C{1};

%% set some fixed parameters
stim_time = [-5e-3 15e-3];

%%
if ischar(ich)
    ich = find(strcmp(ich,chLabels));
end

if ischar(jch)
    jch = find(strcmp(jch,chLabels));
end

stim_idx = elecs(ich).stim_idx;
stim_indices = round(stim_time(1)*fs):round(stim_time(2)*fs);
stim_indices = stim_indices + stim_idx - 1;



% Get the eeg
eeg = elecs(ich).avg(:,jch);

% find the time points that exclude the stim artifact
not_stim_idx = find(~ismember(1:length(eeg),stim_indices));

n1_arr = elecs(ich).N1;
n2_arr = elecs(ich).N2;
n1_idx = stim_idx+n1_arr(jch,2) + 1;
n2_idx = stim_idx+n2_arr(jch,2) + 1;

n1_time = convert_indices_to_times(n1_idx,stim.fs,elecs(ich).times(1));
n2_time = convert_indices_to_times(n2_idx,stim.fs,elecs(ich).times(1));

eeg_times = convert_indices_to_times(1:length(eeg),stim.fs,elecs(ich).times(1));
plot(eeg_times,eeg,'linewidth',1,'Color',[0.6 0.6 0.6]);
hold on
if ~isnan(n1_idx)
    plot(n1_time,eeg(n1_idx),'rX','markersize',6,'linewidth',0.5);
    text(n1_time+0.01,eeg(n1_idx),sprintf('N1 z: %1.1f, %1.1f ms',n1_arr(jch,1),n1_time*1000),...
        'fontsize',4,'Color','red')
end
if ~isnan(n2_idx) % 09-02-21 add n2
    plot(n2_time,eeg(n2_idx),'bX','markersize',6,'linewidth',0.5);
    text(n2_time+0.01,eeg(n2_idx),sprintf('N2 z: %1.1f, %1.1f ms',n2_arr(jch,1),n2_time*1000),...
        'fontsize',4,'Color','blue')
end
%plot(n2_time,eeg(n2_idx),'go','markersize',20,'linewidth',4);



set(gca,'fontsize',8)
set(gca,'fontname','arial')
% fix y limits to be based on eeg not stim artifact
yl = [min(eeg(not_stim_idx)) max(eeg(not_stim_idx))];
offset = .2*diff(yl);
yl(1) = yl(1) - offset;
yl(2) = yl(2) + offset;

ylim(yl);
yticks([yl(1),0,yl(2)])
yticklabels({sprintf('%d uV',round(yl(1))),'0',sprintf('%d uV',round(yl(2)))})
xticklocs = [0 0.6];
xticks(xticklocs)
temp_xticklabels = cell(length(xticks),1);
for i = 1:length(xticks)
    temp_xticklabels{i} = sprintf('%d ms',xticklocs(i)*1000);
end
xticklabels(temp_xticklabels);
plot([0 0],ylim,'k--','linewidth',1);
% can plot n1 and n2 times or exclude
%plot([n1_time n1_time],ylim,'r--','linewidth',1);
%plot([n2_time n2_time],ylim,'b--','linewidth',1);
%
title(sprintf('%s -> %s',chLabels{ich},chLabels{jch}))
%}

xlim([elecs(ich).times(1) elecs(ich).times(2)])

end
