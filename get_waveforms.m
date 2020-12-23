function elecs = get_waveforms(elecs,stim)

% Should I normalize???

%% Parameters
idx_before_stim = 20;
n1_time = [16e-3 50e-3];
n2_time = [50e-3 300e-3];

n1_idx = round(n1_time*stim.fs);
n2_idx = round(n2_time*stim.fs);


% Loop over elecs
for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    n1 = zeros(size(elecs(ich).avg,2),2);
    n2 = zeros(size(elecs(ich).avg,2),2);
    
    % Loop over channels within this elec
    for jch = 1:size(elecs(ich).avg,2)
    
        % Get the eeg
        eeg = elecs(ich).avg(:,jch);
        stim_idx = elecs(ich).stim_idx;
        
        % Get the baseline
        baseline = mean(eeg(1:stim_idx-idx_before_stim));
        
        % redefine n1 and n2 relative to beginning of eeg
        n1_idx = n1_idx + stim_idx;
        n2_idx = n2_idx + stim_idx;
        
        % Get the eeg in the n1 and n2 time
        n1_eeg = eeg(n1_idx(1):n1_idx(2));
        n2_eeg = eeg(n2_idx(1):n2_idx(2));
        
        % subtract baseline and take absolute value
        n1_eeg_abs = abs(n1_eeg-baseline);
        n2_eeg_abs = abs(n2_eeg-baseline);
        
        % find the identity of the peaks
        [n1_peak,n1_peak_idx] = max(n1_eeg_abs);
        [n2_peak,n2_peak_idx] = max(n2_eeg_abs);
        
        % redefine idx relative to time after stim
        n1_peak_idx = n1_peak_idx + n1_idx(1) - stim_idx;
        n2_peak_idx = n2_peak_idx + n2_idx(1) - stim_idx;
        
        % store
        n1(jch,:) = [n1_peak,n1_peak_idx];
        n2(jch,:) = [n2_peak,n2_peak_idx];
        
    end
    
    % add to struct
    elecs(ich).n1 = n1;
    elecs(ich).n2 = n2;
    
end

end