function elecs = get_waveforms(elecs,stim)


%% Parameters
idx_before_stim = 20;
n1_time = [15e-3 50e-3];
n2_time = [50e-3 300e-3];
stim_time = [-5e-3 15e-3];
stim_val_thresh = 1e3;
rel_thresh = 3;
fs = stim.fs;

n1_idx = floor(n1_time*fs);
n2_idx = floor(n2_time*fs);
stim_indices = floor(stim_time*fs);


% Loop over elecs
for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    n1 = zeros(size(elecs(ich).avg,2),2);
    n2 = zeros(size(elecs(ich).avg,2),2);
    
    stim_idx = elecs(ich).stim_idx;
    
    % redefine n1 and n2 relative to beginning of eeg
    temp_n1_idx = n1_idx + stim_idx - 1;
    temp_n2_idx = n2_idx + stim_idx - 1;
    temp_stim_idx = stim_indices + stim_idx - 1;
    
    
    % Loop over channels within this elec
    for jch = 1:size(elecs(ich).avg,2)
    
        % Get the eeg
        eeg = elecs(ich).avg(:,jch);

        % Get the baseline
        baseline = mean(eeg(1:stim_idx-idx_before_stim));
      
        % Get the eeg in the stim time
        stim_eeg = abs(eeg(temp_stim_idx(1):temp_stim_idx(2))-baseline);
        
        % Get the eeg in the n1 and n2 time
        n1_eeg = eeg(temp_n1_idx(1):temp_n1_idx(2));
        n2_eeg = eeg(temp_n2_idx(1):temp_n2_idx(2));
        
        % subtract baseline
        n1_eeg_abs = abs(n1_eeg-baseline);
        n2_eeg_abs = abs(n2_eeg-baseline);
        
        % Get sd of baseline
        baseline_sd = std(eeg(1:stim_idx-idx_before_stim));

        % convert n1_eeg_abs to z score
        n1_z_score = n1_eeg_abs/baseline_sd;
        n2_z_score = n2_eeg_abs/baseline_sd;
        
        %% find the identity of the peaks
        [pks,locs] = findpeaks(n1_z_score,'MinPeakDistance',5e-3*fs);
        [n1_peak,I] = max(pks); % find the biggest
        n1_peak_idx = round(locs(I));
        if isempty(n1_peak)
            n1_peak = nan;
            n1_peak_idx = nan;
        end
        
        [pks,locs] = findpeaks(n2_z_score,'MinPeakDistance',5e-3*fs);
        [n2_peak,I] = max(pks); % find the biggest
        n2_peak_idx = round(locs(I));
        if isempty(n2_peak)
            n2_peak = nan;
            n2_peak_idx = nan;
        end
        
        
        % redefine idx relative to time after stim
        eeg_rel_peak_idx = n1_peak_idx + temp_n1_idx(1) - 1;
        n1_peak_idx = n1_peak_idx + temp_n1_idx(1) - 1 - stim_idx - 1;
        n2_peak_idx = n2_peak_idx + temp_n2_idx(1) - 1 - stim_idx - 1;

        % store   
        n1(jch,:) = [n1_peak,n1_peak_idx];
        n2(jch,:) = [n2_peak,n2_peak_idx];
        
        
        %% Do various things to reject likely artifact
        % 1:
        % If sum of abs value in stim period is above a certain threshold
        % relative to sum of abs value in n1 period, throw out n1
        if sum(stim_eeg) > rel_thresh * sum(n1_eeg_abs)
            n1(jch,:) = [nan nan];
        end
        
        % 2:
        % If anything too big in whole period, throw it out
        if max(abs(eeg(temp_stim_idx(1):temp_n2_idx(end))-nanmedian(eeg))) > 1e3
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        end
        
        % 3:
        % If big DC shift, throw it out
        %{
        median_n2_diff = abs(nanmedian(eeg(length(eeg)-200:end)) - baseline);
        if median_n2_diff/baseline_sd > 6
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        end
        %}
        
        % 4:
        % If no return to "baseline" between stim and N1, throw it out
        %
        [max_stim,stim_max_idx] = max(stim_eeg);
        stim_max_idx = stim_max_idx + temp_stim_idx(1) - 1;
        if ~isnan(n1_peak_idx)
            
            
            % If there's no part in between close to baseline
            close_to_baseline = 0.1*abs(eeg(stim_max_idx)-baseline);
            
            if 0
                plot(eeg)
                hold on
                plot(stim_max_idx,eeg(stim_max_idx),'o')
                plot(eeg_rel_peak_idx,eeg(eeg_rel_peak_idx),'o')
                plot(xlim,[baseline+close_to_baseline baseline+close_to_baseline])
                plot(xlim,[baseline-close_to_baseline baseline-close_to_baseline])
                pause
                close(gcf)
            end
            
            if ~any(abs(eeg(stim_max_idx:eeg_rel_peak_idx) - baseline) < close_to_baseline)
                n1(jch,:) = [nan nan];
                n2(jch,:) = [nan nan];
            end
        end
       
        
        
        %{
        % ERIN JUST REMOVED THIS
        if max(stim_eeg) > rel_thresh*max(n1_eeg_abs)
            n1(jch,:) = [nan nan];
        end
        %}
        
        % If the sum of the absolute value in the stim period is above a
        % certain threshold, throw out n1 because I am likely to catch stim
        % rather than n1  
        % ERIN JUST REMOVED THIS
        %{
        if sum((stim_eeg)) > stim_val_thresh
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        end
        %}
        
        
        if 0
            figure
            plot(eeg)
            hold on
            plot([temp_stim_idx(1) temp_stim_idx(1)],ylim)
            plot([temp_n2_idx(end) temp_n2_idx(end)],ylim)
            
        end
        
        
        if 0
           figure
            set(gcf,'position',[106 388 1335 410])
            plot(eeg,'linewidth',2)
            hold on
            plot([temp_stim_idx(1) temp_stim_idx(1)],get(gca,'ylim'),'k--')
            plot([temp_stim_idx(2) temp_stim_idx(2)],get(gca,'ylim'),'k--')

            plot([temp_n1_idx(1) temp_n1_idx(1)],get(gca,'ylim'),'k')
            plot([temp_n1_idx(2) temp_n1_idx(2)],get(gca,'ylim'),'k')

            plot(old_n1_peak+ temp_n1_idx(1)-1,eeg(old_n1_peak+temp_n1_idx(1)-1),'o')
            xt = get(gca, 'XTick');                                 
            set(gca, 'XTick', xt, 'XTickLabel', xt/stim.fs+elecs(ich).times(1))
            pause
            hold off 
        end
        
    end
    
    % add to struct
    elecs(ich).N1 = n1;
    elecs(ich).N2 = n2;
    
end

end

function time = convert_idx_to_time(idx,times)

    time = linspace(times(1),times(2),length(idx));

end