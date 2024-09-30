function pretty_random_keeps(out)

%% Parameters
pretty = 1;
n_to_plot = 25; % how many total to show
n_per_line = 5;
n_lines = 5;
n1_time = [10e-3 50e-3];
zoom_times = [-300e-3 300e-3];
zoom_factor = 2;
which_n = 1;

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
out_folder = [results_folder,'validation/',name,'/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

%% Pick intracranial chs with bipolar signal
keep_chs = get_chs_to_ignore(out.bipolar_labels);

%% Get rejection details arrays
thresh = out.rejection_details(which_n).thresh;
which = out.rejection_details(which_n).which;

sig_avg = out.rejection_details(which_n).reject.sig_avg;
pre_thresh = out.rejection_details(which_n).reject.pre_thresh;
at_thresh = out.rejection_details(which_n).reject.at_thresh;
keep = out.rejection_details(which_n).reject.keep;


any_reject = sig_avg == 1| pre_thresh == 1 | at_thresh == 1;

% Calculate total numbers
nkeep = sum(keep(:) == 1);
nreject = sum(any_reject(:) == 1);
nunstim = sum(isnan(keep(:)));

if nunstim+nreject+nkeep ~= size(keep,1)*size(keep,1)
    error('numbers do not add up');
end

% Just do keeps
for j = 1
    if j == 1
        thing = keep;
        cat = 'New Keep';
    else
        thing = any_reject;
        cat = 'Reject Any';
    end
    
    meet_criteria = find(thing==1);
    
    % Restrict to those on keep chs
    [row,col] = ind2sub(size(keep),meet_criteria);
    meet_criteria(keep_chs(row) == false) = [];
    col(keep_chs(row) == false) = [];
    meet_criteria(keep_chs(col) == false) = [];
    
    % Initialize figure
    figure
    set(gcf,'position',[100 100 1200 1000])
    t = tiledlayout(n_lines,n_per_line,'padding','compact','tilespacing','compact');
    
 
    % Pick a random N
    to_plot = randsample(meet_criteria,min(n_to_plot,length(meet_criteria)));
    
    % Loop through these
    for i = 1:length(to_plot)
        
        ind = to_plot(i);
        
        % convert this to row and column
        [row,col] = ind2sub(size(keep),ind);
        
        % get why it was rejected
        why = nan;
        if j == 2
            if sig_avg(row,col) == 1
                why = 'averaging';
            end
            if pre_thresh(row,col) == 1
                if ~isnan(why)
                    error('what');
                end
                why = 'artifact';
            end
            if at_thresh(row,col) == 1
                if ~isnan(why)
                    error('what');
                end
                why = 'threshold';
            end
                
        end
        
        % Get the waveform
        avg = out.elecs(row).avg(:,col);
        times = out.elecs(row).times;
        eeg_times = convert_indices_to_times(1:length(avg),out.other.stim.fs,times(1));
        wav =  out.elecs(row).(which)(col,:);
        stim_idx = out.elecs(row).stim_idx;
        wav_idx = wav(2)+stim_idx+1;
        wav_time = convert_indices_to_times(wav_idx,out.other.stim.fs,times(1));
        n1_idx = floor(n1_time*out.other.stim.fs);
        temp_n1_idx = n1_idx + stim_idx - 1;
        
        
        % Plot
        nexttile
        plot(eeg_times,avg,'k','linewidth',2);
        hold on
        
        if ~isnan(wav(1))
            
            if ~pretty
            plot(wav_time,avg(wav_idx),'bX','markersize',15,'linewidth',4);
            text(wav_time+0.01,avg(wav_idx),sprintf('%s z-score: %1.1f',...
                which,wav(1)), 'fontsize',15)
            end
        end
        %xlim([eeg_times(1) eeg_times(end)])
        xlim([zoom_times(1) zoom_times(2)]);
        
        % Zoom in (in the y-dimension) around the maximal point in the N1
        % time period
        height = max(abs(avg(temp_n1_idx(1):temp_n1_idx(2))-median(avg)));
        if ~any(isnan(avg))
            ylim([median(avg)-zoom_factor*height,median(avg)+zoom_factor*height]);
        end
        
        
        labels = out.bipolar_labels;
        stim_label = labels{row};
        resp_label = labels{col};
        pause(0.1)
        xl = xlim;
        yl = ylim;
        if ~pretty
            text(xl(1),yl(2),sprintf('Stim: %s\nResponse: %s',stim_label,resp_label),...
                'horizontalalignment','left',...
                'verticalalignment','top','fontsize',10);
        end
        plot([0 0],ylim,'k--');
        set(gca,'fontsize',20)
        if pretty
            yticklabels([])
            %xticklabels([])
            xtl = xticklabels;
            xtlc = cellfun(@(x) sprintf('%s s',x),xtl,'uniformoutput',false);
            %xlabel('Time (s)')
            xticklabels(xtlc)
        end
        if j == 2
            title(why)
        end
    end
    
    if pretty == 0
        title(t,sprintf('%s %s z-score threshold %1.1f',cat,which,thresh));
    end
    
    % Save the figure
    if pretty
        fname = sprintf('%s_%sthresh_%d_pretty',cat,which,thresh);
    else
        fname = sprintf('%s_%sthresh_%d',cat,which,thresh);
    end
    print(gcf,[out_folder,fname],'-dpng');
    

    
end

    


end