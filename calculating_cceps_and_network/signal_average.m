function elecs = signal_average(values,elecs,stim,chLabels,do_bipolar)

%% Parameters 
time_to_take = [-100e-3 800e-3];
idx_to_take = round(stim.fs * time_to_take);

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
    elecs(ich).all = zeros(idx(1,2)-idx(1,1)+1,size(values,2),size(idx,1));
    
    % Loop over all other channels
    for jch = 1:size(values,2)
       % fprintf('\n   Doing subchannel %d of %d',jch,size(values,2));
        
        % get those bits of eeg
        eeg_bits = zeros(length(arts),idx(1,2)-idx(1,1)+1);
        for j = 1:size(idx,1)
            if do_bipolar
                eeg_bits(j,:) = bipolar_montage(values(idx(j,1):idx(j,2),:),jch,chLabels);
            else
                eeg_bits(j,:) = values(idx(j,1):idx(j,2),jch);
            end
            elecs(ich).all(:,jch,j) = eeg_bits(j,:);
        end

        % Average the eeg
        eeg_avg = mean(eeg_bits,1);

        % add to structure
        elecs(ich).avg(:,jch) = eeg_avg;
        
    
    end
    
    elecs(ich).stim_idx = -idx_to_take(1);
    elecs(ich).times = time_to_take;
end

end