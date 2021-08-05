function random_rejections_keeps(out)

%% Parameters
n_per_line = 5;
n_lines = 5;
n_to_plot = 25;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end
name = out.name;
name = strsplit(out.name,'_');
name = name{1};
out_folder = [results_folder,'validation/',name,'/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end


%% Get rejection details arrays
reject = out.details.reject;
thresh = out.details.thresh;
which = out.details.which;

% Loop through rejection types
for cat = fields(reject)'
    cat = char(cat);
    
    if strcmp(cat,'sig_avg') == 1
        perc_rej = 100*sum(reject.(cat)(:) == 1)/(size(reject.(cat),1)*size(reject.(cat),2));
        fprintf('\n%1.1f%% rejected at signal averaging step, cannot analyze here\n',perc_rej);
        continue;
    end
    
    % Initialize figure
    figure
    set(gcf,'position',[100 100 1200 1000])
    t = tiledlayout(n_lines,n_per_line,'padding','tight','tilespacing','tight');
    
    % find 1s (stim-response ch pairs/possible cceps meeting this rejection
    % criteria)
    meet_criteria = find(reject.(cat)==1);
    
    % Pick a random N
    to_plot = randsample(meet_criteria,min(n_to_plot,length(meet_criteria)));
    
    % Loop through these
    for i = 1:length(to_plot)
        
        ind = to_plot(i);
        
        % convert this to row and column
        [row,col] = ind2sub(size(reject.(cat)),ind);
        
        % Get the waveform
        avg = out.elecs(row).avg(:,col);
        times = out.elecs(row).times;
        eeg_times = convert_indices_to_times(1:length(avg),out.stim.fs,times(1));
        wav =  out.elecs(row).(which)(col,:);
        stim_idx = out.elecs(row).stim_idx;
        wav_idx = wav(2)+stim_idx+1;
        wav_time = convert_indices_to_times(wav_idx,out.stim.fs,times(1));
        
        
        % Plot
        nexttile
        plot(eeg_times,avg,'k','linewidth',2);
        hold on
        plot([0 0],ylim,'k--');
        if ~isnan(wav(1))
            plot(wav_time,avg(wav_idx),'bX','markersize',10,'linewidth',4);
            text(wav_time+0.01,avg(wav_idx),sprintf('%s z-score: %1.1f',...
                which,wav(1)), 'fontsize',15)
        end
        xlim([eeg_times(1) eeg_times(end)])
        labels = out.bipolar_labels;
        stim_label = labels{row};
        resp_label = labels{col};
        pause(0.1)
        xl = xlim;
        yl = ylim;
        text(xl(1),yl(2),sprintf('Stim: %s\nResponse: %s',stim_label,resp_label),...
            'horizontalalignment','left',...
            'verticalalignment','top','fontsize',10);
              
    end
    
    title(t,sprintf('%s %s z-score threshold %1.1f',cat,which,thresh));
    
    % Save the figure
    fname = sprintf('%s_%sthresh_%d',cat,which,thresh);
    print(gcf,[out_folder,fname],'-dpng');
    
end


end