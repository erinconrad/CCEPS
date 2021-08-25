function elecs = signal_average(values,elecs,stim)

%% Parameters 
time_to_take = [-500e-3 800e-3];
fs = stim.fs;
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
    elecs(ich).all_bad = zeros(size(values,2),1);
    
    % Get stim idx
    stim_idx = elecs(ich).stim_idx;
    stim_indices = stim_indices + stim_idx - 1;
    
    % Initialize array listing number of bad trials
    elecs(ich).n_bad_trials = zeros(size(values,2),1);
    
    
    % Loop over all other channels
    for jch = 1:size(values,2)
       % fprintf('\n   Doing subchannel %d of %d',jch,size(values,2));
        
        % get those bits of eeg
        eeg_bits = zeros(length(arts),idx(1,2)-idx(1,1)+1);
        keep = ones(length(arts),1);
               
        for j = 1:size(idx,1)
            
            bit = values(idx(j,1):idx(j,2),jch);
            
            
            % skip if all nans
            if sum(~isnan(bit)) == 0
                eeg_bits(j,:) = bit;
                keep(j) = 0;
                continue
            end
            

            % Remove mean (so that DC differences don't affect calculation)
            bit = bit-mean(bit);
            
            all_idx = 1:length(bit);
            non_stim_idx = all_idx;
            non_stim_idx(ismember(non_stim_idx,stim_indices)) = [];


            % If ANY really high values outside of stim time, throw it out
            bit_no_stim = bit;
            bit_no_stim(stim_indices) = nan;
            if max(abs(bit_no_stim)) > 1e3
                keep(j) = 0;
                elecs(ich).n_bad_trials(j) = elecs(ich).n_bad_trials(j) + 1;
            end
            %}
            
            if 0
                plot(bit)
                hold on
                plot(bit_no_stim)
                plot([stim_indices(1) stim_indices(1)],ylim)
                plot([stim_indices(end) stim_indices(end)],ylim)
                plot(xlim,[1e3 1e3])
                plot(xlim,[-1e3 -1e3])
            end
            
            eeg_bits(j,:) = bit;
        end
        
        
        %% Average the eeg
        if sum(keep) == 0 % all bad!
            eeg_avg = nanmean(eeg_bits,1);
            all_bad = 1;
        else
            eeg_avg = nanmean(eeg_bits(keep == 1,:),1);
            all_bad = 0;
        end
   

        %% add to structure
        elecs(ich).avg(:,jch) = eeg_avg;
        elecs(ich).all_bad(jch) = all_bad;
    
    end
    
    
end

end