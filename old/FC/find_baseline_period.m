function baseline_indices = find_baseline_period(eeg,fs)

buffer = 1e-1; % 100 ms of buffer
min_time = 30;
buffer_idx = buffer*fs;
baseline_dur = min_time*fs;

% Take out the last buffer
eeg(end-buffer_idx:end,:) = [];

% Take cumulative sum across time
rm_nan_eeg = eeg;
rm_nan_eeg(isnan(eeg)) = 0;
eeg_cumsum = cumsum(rm_nan_eeg,1);

% Get a count of the non nans and non zeros across electrodes
non_nan_cumsum = sum(~isnan(eeg_cumsum) & eeg_cumsum ~= 0,2);

% Take the first non zero one. This is the first time point at which not
% all eeg signals are nan
first_non_nan = find(non_nan_cumsum~=0);
first_non_nan = first_non_nan(1);

% Get time between first non nan and end
nindices = size(eeg,1)-first_non_nan+1;
if nindices < baseline_dur
    baseline_indices = [];
else
    % Take the last 10 seconds
    baseline_indices = size(eeg,1)-baseline_dur:size(eeg,1);
end
    


end