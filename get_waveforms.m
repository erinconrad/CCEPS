function elecs = get_waveforms(elecs,stim,chLabels)


%% Parameters
idx_before_stim = 20;
n1_time = [10e-3 30e-3];
n2_time = [50e-3 300e-3];
stim_time = [-5e-3 10e-3];
stim_val_thresh = 5e4;
rel_thresh = 4;

n1_idx = floor(n1_time*stim.fs);
n2_idx = floor(n2_time*stim.fs);
stim_indices = floor(stim_time*stim.fs);


% Loop over elecs
for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    n1 = zeros(size(elecs(ich).avg,2),2);
    n2 = zeros(size(elecs(ich).avg,2),2);
    
    stim_idx = elecs(ich).stim_idx;
    
    % redefine n1 and n2 relative to beginning of eeg
    temp_n1_idx = n1_idx + stim_idx;
    temp_n2_idx = n2_idx + stim_idx;
    temp_stim_idx = stim_indices + stim_idx;
    
    
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
        
        % find the identity of the peaks
        [n1_peak,n1_peak_idx] = max(n1_z_score);
        [n2_peak,n2_peak_idx] = max(n2_z_score);
        
        
        
        if 0
            plot(linspace(elecs(ich).times(1),elecs(ich).times(2),length(eeg)),eeg)
            hold on
            plot([elecs(ich).times(1) (stim_idx-idx_before_stim)/stim.fs+elecs(ich).times(1)],[baseline baseline])
            plot((n1_peak_idx+ temp_n1_idx(1))/stim.fs+elecs(ich).times(1),...
                eeg(n1_peak_idx+ temp_n1_idx(1)),'o')
            title(sprintf('Stim: %s, CCEP: %s\nN1 at %1.1f ms',...
                chLabels{ich},chLabels{jch},((n1_peak_idx + temp_n1_idx(1) -2)/stim.fs+elecs(ich).times(1))*1e3))
            pause
            hold off
        end
        %}
        %{
        plot(eeg)
        hold on
        plot([1 stim_idx - idx_before_stim],[baseline baseline]);
        plot(n1_peak_idx+ temp_n1_idx(1)-1,eeg(n1_peak_idx+temp_n1_idx(1)-1),'o')
        xt = get(gca, 'XTick');                                 
        set(gca, 'XTick', xt, 'XTickLabel', xt/stim.fs+elecs(ich).times(1))
        pause
        hold off
        %}
        
        
        
        % redefine idx relative to time after stim
        n1_peak_idx = n1_peak_idx + temp_n1_idx(1) - stim_idx;
        n2_peak_idx = n2_peak_idx + temp_n2_idx(1) - stim_idx;
        
        
        
        % store   
        n1(jch,:) = [n1_peak,n1_peak_idx];
        n2(jch,:) = [n2_peak,n2_peak_idx];
        
        
        % If sum of abs value in stim period is above a certain threshold
        % relative to sum of abs value in n1 period, throw out n1
        if sum(stim_eeg) > rel_thresh * sum(n1_eeg_abs)
            n1(jch,:) = [nan nan];
        end
        %{
        if max(stim_eeg) > rel_thresh*max(n1_eeg_abs)
            n1(jch,:) = [nan nan];
        end
        %}
        
        % If the sum of the absolute value in the stim period is above a
        % certain threshold, throw out n1 because I am likely to catch stim
        % rather than n1
        
        if sum((stim_eeg)) > stim_val_thresh
            n1(jch,:) = [nan nan];
        end
        %}
        
    end
    
    % add to struct
    elecs(ich).n1 = n1;
    elecs(ich).n2 = n2;
    
end

end

function time = convert_idx_to_time(idx,times)

    time = linspace(times(1),times(2),length(idx));

end