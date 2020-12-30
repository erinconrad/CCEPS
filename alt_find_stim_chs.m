function elecs = alt_find_stim_chs(artifacts,stim,chLabels)


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
discrepancy_bipolar = 0.8;

% Loop through electrodes
for ich = 1:length(artifacts)
    
    % Skip if empty
    if isempty(artifacts{ich}), continue; end
    
    
    curr_ch = artifacts{ich};
    
    nseq = max(unique(curr_ch(:,4)));
    for s = 1:nseq
        
      curr_seq = curr_ch(curr_ch(:,4) == s,:);
        % Loop through other channels
        for jch = 1:length(artifacts)
            if jch == ich, continue; end
            if isempty(artifacts{jch}), continue; end

            test_ch = artifacts{jch};
            nseq2 = max(unique(test_ch(:,4)));
            
            for s2 = 1:nseq2
                
                test_seq = test_ch(test_ch(:,4) == s2,:);
                time_diff = curr_seq(:,1) - test_seq(:,1)'; % matrix with all possible time differences
                num_close = sum(sum(abs(time_diff) < max_distance));
                
                % Are there enough close? If so, it's the same sequence
                if num_close > min_num_close
                    
                   % if ich == 65 && jch == 66, error('what'); end
                    
                    % See which has higher amplitudes
                    curr_amps = sum(abs(curr_seq(:,2)));
                    test_amps = sum(abs(test_seq(:,2)));
                    
                    % if close in amplitude, may be the two channels of a
                    % bipolar stim
                    if (curr_amps > test_amps && test_amps/curr_amps > discrepancy_bipolar) || ...
                            (curr_amps < test_amps && curr_amps/test_amps > discrepancy_bipolar)
                        
                        % In this case, assign it to the lowest numbered
                        % one
                        curr_label = chLabels{ich};
                        test_label = chLabels{jch};
                        
                        % derive the number
                        curr_elec_num = regexp(curr_label,'\d');
                        test_elec_num = regexp(test_label,'\d');
                        
                        if isempty(curr_elec_num)
                            artifacts{ich}(artifacts{ich}(:,4) == s,:) = [];
                            break
                        elseif isempty(test_elec_num)
                            artifacts{jch}(artifacts{jch}(:,4) == s,:) = [];
                            continue;
                        end
                        
                        curr_elec_label = curr_label(1:curr_elec_num-1);
                        curr_elec_num = str2num(curr_label(curr_elec_num(1):end));
                        
                        
                        test_elec_label = test_label(1:test_elec_num-1);
                        test_elec_num = str2num(test_label(test_elec_num(1):end));
                        
                        if test_elec_num == curr_elec_num - 1 && strcmp(curr_elec_label,test_elec_label) % jch lower, keep that one
                            artifacts{ich}(artifacts{ich}(:,4) == s,:) = [];
                        elseif curr_elec_num == test_elec_num - 1 && strcmp(curr_elec_label,test_elec_label) % ich lower, keep that one
                            artifacts{jch}(artifacts{jch}(:,4) == s,:) = [];
                        else % keep higher amplitude one
                            if test_amps > curr_amps
                                artifacts{ich}(artifacts{ich}(:,4) == s,:) = [];
                            else
                                artifacts{jch}(artifacts{jch}(:,4) == s2,:) = [];
                            end
                            
                        end
                        
                    else % not close in amplitude

                        if test_amps > curr_amps
                            artifacts{ich}(artifacts{ich}(:,4) == s,:) = [];
                        else
                            artifacts{jch}(artifacts{jch}(:,4) == s2,:) = [];
                        end
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