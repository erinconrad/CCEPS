function elecs = alt_find_stim_chs(artifacts,stim)


%% Show current artifacts
if 0
figure
count = 0;
for i = 1:length(artifacts)
    if isempty(artifacts{i})
        continue;
    end
    count = count + 1;
    plot(artifacts{i}(:,1),count,'o')
    hold on
    
end
end

%% Parameters
min_num_close = 10;
max_distance = 10;

% Loop through electrodes
for ich = 1:length(artifacts)
    
    % Skip if empty
    if isempty(artifacts{ich}), continue; end
    
    
    curr_ch = artifacts{ich};
    
    nseq = max(unique(curr_ch(:,3)));
    for s = 1:nseq
        
      curr_seq = curr_ch(curr_ch(:,3) == s,:);
        % Loop through other channels
        for jch = 1:length(artifacts)
            if jch == ich, continue; end
            if isempty(artifacts{jch}), continue; end

            test_ch = artifacts{jch};
            nseq2 = max(unique(test_ch(:,3)));
            
            for s2 = 1:nseq2
                
                test_seq = test_ch(test_ch(:,3) == s2,:);
                time_diff = curr_seq(:,1) - test_seq(:,1)'; % matrix with all possible time differences
                num_close = sum(sum(abs(time_diff) < max_distance));
                
                % Are there enough close? If so, it's the same sequence
                if num_close > min_num_close
                    
                    % See which has higher amplitudes
                    curr_amps = sum(abs(curr_seq(:,2)));
                    test_amps = sum(abs(test_seq(:,2)));
                    
                    if test_amps > curr_amps
                        artifacts{ich}(artifacts{ich}(:,3) == s,:) = [];
                    else
                        artifacts{jch}(artifacts{jch}(:,3) == s2,:) = [];
                    end
                    
                end
                
            end
        
        end
    end
    
end

for ich = 1:length(artifacts)
    elecs(ich).arts = round(artifacts{ich});
end

end