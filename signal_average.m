function elecs = signal_average(values,elecs,stim)

%% Parameters 
time_to_take = [-100e-3 800e-3];
idx_to_take = round(stim.fs * time_to_take);

for ich = 1:length(elecs)
    if isempty(elecs(ich).arts)
        continue;
    end
    
    % Get stim artifacts
    arts = elecs(ich).arts;

    % Get the indices to take 
    idx = [arts+idx_to_take(1),arts+idx_to_take(2)];
    
    % Initialize avg
    elecs(ich).avg = zeros(idx(1,2)-idx(1,1)+1,size(values,2));
    
    % Loop over all other channels
    for jch = 1:size(values,2)
        
        eeg = values(:,jch);
        
        % get those bits of eeg
        eeg_bits = zeros(length(arts),idx(1,2)-idx(1,1)+1);
        for j = 1:size(idx,1)
            eeg_bits(j,:) = eeg(idx(j,1):idx(j,2));
        end

        % Average the eeg
        eeg_avg = mean(eeg_bits,1);

        % add to structure
        elecs(ich).avg(:,jch) = eeg_avg;
        
    
    end
    
    elecs(ich).stim_idx = -idx_to_take(1);
    
end

end