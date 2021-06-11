function show_avg(out,ich,jch,save_plot)

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
chLabels = out.chLabels;
wav = out.waveform;
C = strsplit(out.name,'_');
name_first = C{1};


if ischar(ich)
    ich = find(strcmp(ich,chLabels));
end

if ischar(jch)
    jch = find(strcmp(jch,chLabels));
end

stim_idx = elecs(ich).stim_idx;
    


% Get the eeg
eeg = elecs(ich).avg(:,jch);

n1_arr = elecs(ich).N1;
n2_arr = elecs(ich).N2;
n1_idx = stim_idx+n1_arr(jch,2) + 1;
n2_idx = stim_idx+n2_arr(jch,2) + 1;

if save_plot
    figure
    set(gcf,'position',[168 424 1273 374]);
end

n1_time = convert_indices_to_times(n1_idx,stim.fs,elecs(ich).times(1));
n2_time = convert_indices_to_times(n2_idx,stim.fs,elecs(ich).times(1));

eeg_times = convert_indices_to_times(1:length(eeg),stim.fs,elecs(ich).times(1));
plot(eeg_times,eeg,'k','linewidth',2);
hold on
if ~isnan(n1_idx)
    plot(n1_time,eeg(n1_idx),'bX','markersize',20,'linewidth',4);
    text(n1_time+0.01,eeg(n1_idx),sprintf('N1 z-score: %1.1f',n1_arr(jch,1)),...
        'fontsize',20)
end
%plot(n2_time,eeg(n2_idx),'go','markersize',20,'linewidth',4);



set(gca,'fontsize',25)
set(gca,'fontname','Monospac821 BT')
yl = get(gca,'ylim');
yticks([yl(1),yl(2)])
yticklabels({sprintf('%d uV',round(yl(1))),sprintf('%d uV',round(yl(2)))})
xticklocs = [0 0.6];
xticks(xticklocs)
temp_xticklabels = cell(length(xticks),1);
for i = 1:length(xticks)
    temp_xticklabels{i} = sprintf('%d ms',xticklocs(i)*1000);
end
xticklabels(temp_xticklabels);
plot([0 0],ylim,'k--','linewidth',2);

%
title(sprintf('%s Stim: %s, Response: %s',...
    name_first ,chLabels{ich},chLabels{jch}))
%}

xlim([elecs(ich).times(1) elecs(ich).times(2)])

if save_plot
    print(gcf,[results_folder,'plots/',name_first ,'_',chLabels{ich},'_',chLabels{jch}],'-dpng');
end

end
