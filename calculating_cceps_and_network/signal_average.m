function elecs = signal_average(values,elecs,stim)

%% Parameters 
time_to_take = [-500e-3 800e-3];
fs = stim.fs;
lpf = 30; % cut-off frequency for low pass filter
idx_to_take = round(fs * time_to_take);
stim_time = [-5e-3 15e-3];
stim_indices = round(stim_time(1)*fs):round(stim_time(2)*fs);

for ich = 1:length(elecs)
    
    %fprintf('\nDoing ch %d of %d',ich,length(elecs));
    if isempty(elecs(ich).arts)
        continue;
    end
    
    % Get stim artifacts
    arts = elecs(ich).arts(:,1);

    % Get the indices to take 
    idx = [arts+idx_to_take(1),arts+idx_to_take(2)];
    
    % Initialize avg
    elecs(ich).avg = zeros(idx(1,2)-idx(1,1)+1,size(values,2));
    
    elecs(ich).stim_idx = -idx_to_take(1);
    elecs(ich).times = time_to_take;
    
    % Get stim idx
    stim_idx = elecs(ich).stim_idx;
    stim_indices = stim_indices + stim_idx - 1;
    
    % Loop over all other channels
    for jch = 1:size(values,2)
       % fprintf('\n   Doing subchannel %d of %d',jch,size(values,2));
        
        % get those bits of eeg
        eeg_bits = zeros(length(arts),idx(1,2)-idx(1,1)+1);
               
        for j = 1:size(idx,1)
            
            bit = values(idx(j,1):idx(j,2),jch);
            
            
            % skip if all nans
            if sum(~isnan(bit)) == 0
                eeg_bits(j,:) = bit;
                continue
            end
            
            % Low pass filter
            %bit = lowpass(bit,lpf,fs);
            
            % Remove mean (so that DC differences don't affect calculation)
            bit = bit-mean(bit);
            
            all_idx = 1:length(bit);
            non_stim_idx = all_idx;
            non_stim_idx(ismember(non_stim_idx,stim_indices)) = [];
            
            if 0
                plot(bit)
                hold on
                plot([stim_indices(1) stim_indices(1)],ylim)
                plot([stim_indices(end) stim_indices(end)],ylim)
            end
            
            % if there are any really high values outside of stim, throw it out
            %{
            if max(abs(bit(non_stim_idx))) > 1e3
                bit = nan(size(bit));
            end
            %}
            % If ANY really high values, throw it out
            if max(abs(bit)) > 1e3
                bit = nan(size(bit));
            end
            %}
            
            eeg_bits(j,:) = bit;
        end
        
        
        %% LPF the output prior to averaging
        % Take the transpose
        signal = eeg_bits';
        
        % make nan columns zero (so it won't break the filter)
        nan_cols = sum(~isnan(signal),1) == 0;
        signal(:,nan_cols) = 0;
        
        % LPF
        signal = lowpass(signal,lpf,fs);
        
        % Make the nan columns nan again
        signal(:,nan_cols) = nan;
        
        % retranspose
        eeg_bits = signal';

        %% Average the eeg
        eeg_avg = nanmean(eeg_bits,1);
        
        

        %% add to structure
        elecs(ich).avg(:,jch) = eeg_avg;
        
    
    end
    
    
end

end