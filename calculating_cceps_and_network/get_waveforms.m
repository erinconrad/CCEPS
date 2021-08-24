function elecs = get_waveforms(elecs,stim)


%% Parameters
idx_before_stim = 20;
n1_time = [15e-3 50e-3];
n2_time = [50e-3 300e-3];
stim_time = [-5e-3 15e-3];
tight_stim_time = [-5e-3 10e-3];
stim_val_thresh = 1e3;
rel_thresh = 3;
fs = stim.fs;
max_crossings = 3;

n1_idx = floor(n1_time*fs);
n2_idx = floor(n2_time*fs);
stim_indices = floor(stim_time*fs);
tight_stim_indices = floor(tight_stim_time*fs);

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
    temp_tight_stim = tight_stim_indices + stim_idx-1;
    
    
    % Loop over channels within this elec
    for jch = 1:size(elecs(ich).avg,2)
    
        % Get the eeg
        eeg = elecs(ich).avg(:,jch);
        
        % skip if all trials are bad
        if elecs(ich).all_bad(jch) == 1
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
            continue
        end
   
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
        %}
        
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
        
        if 0
            figure
            plot(eeg)
            hold on
            plot([temp_n1_idx(1) temp_n1_idx(1)],ylim)
            plot([temp_n1_idx(2) temp_n1_idx(2)],ylim)
            plot(xlim,[baseline baseline])
        end
        
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
        % If the EEG signal in the N1 period crosses a line connecting its
        % first and last point more than twice, throw it out
        n_crossings = count_crossings(n1_eeg,baseline);
      
        if n_crossings > max_crossings
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        end
        %}
        
        % 4:
        % If no return to "baseline" between stim and N1, throw it out
        %
        return_to_baseline_before = 0;
        signed_tight_stim_eeg = eeg(temp_tight_stim(1):temp_tight_stim(2))-baseline;
        
        if ~isnan(n1_peak_idx)
                       
            % if N1 above baseline
            if eeg(eeg_rel_peak_idx) - baseline > 0
                % Then look at max stim
                [max_stim,stim_max_idx] = max(signed_tight_stim_eeg);
                stim_height = max_stim - baseline;
                n1_height = eeg(eeg_rel_peak_idx) - baseline;
            else
                % Look at min stim
                [max_stim,stim_max_idx] = min(signed_tight_stim_eeg);
                stim_height = baseline - max_stim;
                n1_height =  baseline - eeg(eeg_rel_peak_idx);
            end
            stim_max_idx = stim_max_idx + temp_tight_stim(1) - 1;
      
            % Only invoke this rule if the height of the stim artifact
            % larger than height of n1
            if  stim_height > n1_height

                % If there's no part in between close to baseline
                bl_range = [baseline-1*baseline_sd,baseline+1*baseline_sd];

                if eeg(eeg_rel_peak_idx) - baseline > 0
                     % check if it gets below the upper baseline range
                    if any(eeg(stim_max_idx:eeg_rel_peak_idx) < bl_range(2))
                        return_to_baseline_before = 1;
                    end
                else
                    % check if it gets above the lower baseline range
                    if any(eeg(stim_max_idx:eeg_rel_peak_idx) > bl_range(1))
                        return_to_baseline_before = 1;
                    end
                end
            
            
                if 0
                    figure
                    plot(eeg)
                    hold on
                    plot(stim_max_idx,eeg(stim_max_idx),'o')
                    plot(eeg_rel_peak_idx,eeg(eeg_rel_peak_idx),'o')
                    plot(xlim,[bl_range(1) bl_range(1)])
                    plot(xlim,[bl_range(2) bl_range(2)])
                    if return_to_baseline_before
                        title('Ok')
                    else
                        title('Not ok')
                    end
                end

                if ~return_to_baseline_before
                    n1(jch,:) = [nan nan];
                    n2(jch,:) = [nan nan]; 
                end
            
            end
        
        end
        %}
       
        % 5:
        % if no return to baseline after N1 peak in a certain amount of
        % time, throw it out
        if ~isnan(n1_peak_idx)
            time_to_return_to_bl = 100e-3; % 50 ms
            idx_to_return_to_bl = eeg_rel_peak_idx+round(time_to_return_to_bl * fs);
            bl_range = [baseline-1*baseline_sd,baseline+1*baseline_sd];
            returns_to_baseline_after = 0;

            % if N1 above baseline
            if eeg(eeg_rel_peak_idx) - baseline > 0

                % check if it gets below the upper baseline range
                if any(eeg(eeg_rel_peak_idx:idx_to_return_to_bl) < bl_range(2))
                    returns_to_baseline_after = 1;
                end

            else

                % check if it gets above the lower baseline range
                if any(eeg(eeg_rel_peak_idx:idx_to_return_to_bl) > bl_range(1))
                    returns_to_baseline_after = 1;
                end

            end

            if ~returns_to_baseline_after
                n1(jch,:) = [nan nan];
                n2(jch,:) = [nan nan];
            end

            if 0
                figure
                plot(eeg)
                hold on
                plot([eeg_rel_peak_idx eeg_rel_peak_idx],ylim)
                plot([idx_to_return_to_bl...
                    idx_to_return_to_bl],ylim)
                plot(xlim,[bl_range(1) bl_range(1)])
                plot(xlim,[bl_range(2) bl_range(2)])
                if returns_to_baseline_after
                    title('Ok');
                else
                    title('Not ok');
                end
            end
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