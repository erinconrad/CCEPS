function elecs = identify_artifacts_within_periods(periods,values,stim,chLabels)

%% Parameters
n_stds = 2;
iqr_mult = 3;
prc = [5 95];

fs = stim.fs;
train_duration = stim.train_duration;
stim_freq = stim.stim_freq;
max_off = 20e-3*fs;
min_off = 500e-3*fs;
allowable_nums = [train_duration:-1:train_duration-2];
goal_diff = stim_freq * fs;
min_agree = 3;

[elec_names,~] = return_contact_and_electrode(chLabels);

%% Fill in missing elecs
for ich = 1:length(periods)
    elecs(ich).arts = [];
end

% Loop through periods
for ich = 1:length(periods)
    if isempty(periods(ich).start_time)
        continue
    end
    
    % Get all contacts on that electrode
    curr_elec = elec_names{ich};
    all_elecs = find(strcmp(elec_names,curr_elec));
    
    elec_arts = cell(length(all_elecs),1);
    
    % Loop over all contacts on that electrode
    for j = 1:length(all_elecs)
        
        jch = all_elecs(j);
    
        eeg = values(periods(ich).start_index:periods(ich).end_index,jch);
        
        %% Switch nans to baseline value
        eeg(isnan(eeg)) = nanmedian(eeg);
        
        hp = eeg;
        %hp = eegfilt(eeg,10,'hp',fs);

        %% Get absolute value of deviation from baseline
        bl = nanmedian(hp);
        dev = hp-bl;

        %% Find the points that cross above the threshold
        a = prctile(hp,prc);
        lower = a(1);
        upper = a(2);
        lower_thresh = bl - (bl-lower)*iqr_mult;
        upper_thresh = bl + (upper-bl)*iqr_mult;

        above_thresh = find(hp > upper_thresh | hp < lower_thresh);
        if 0
        thresh_C = n_stds*nanstd(eeg);
        above_thresh = find(abs_dev > thresh_C);
        end

        if 0
            figure
            %plot(eeg)
            plot(hp)
            hold on

            plot(xlim,[lower_thresh lower_thresh])
            plot(xlim,[upper_thresh upper_thresh])
            plot((above_thresh),hp(above_thresh),'o')
            pause
            close(gcf)
        end

        candidate_arts = above_thresh;

        final_art_idx = find_beat(candidate_arts,max_off,allowable_nums,goal_diff);
        final_arts = candidate_arts(final_art_idx);
        
        elec_arts{j} = final_arts;

        if 0
            figure
            plot(eeg)
            hold on
            %plot(candidate_arts,eeg(candidate_arts),'o','markersize',5)
            plot(final_arts,values(final_arts),'o','markersize',5)
            pause
            close(gcf)

        end
        
        
    
    end
    
    %% Now, take the mode across the artifacts on the different contacts to get final timing
    %n_non_empty = sum(cell2mat(cellfun(@(x) ~isempty(x), elec_arts,'uniformoutput',false)));
    consensus_arts = final_timing(elec_arts,min_agree,max_off,min_off);
    
    
    
    
    if 0
        figure
        eeg = values(periods(ich).start_index:periods(ich).end_index,ich);
        plot(eeg)
        hold on
        %plot(candidate_arts,eeg(candidate_arts),'o','markersize',5)
        plot(consensus_arts,eeg(consensus_arts),'o')
        pause
        close(gcf)

    end
    
    % Re-define time relative to start
    consensus_arts = consensus_arts + periods(ich).start_index - 1;
    elecs(ich).arts = consensus_arts;
    
end

end

function final = final_timing(elec_arts,min_agree,max_off,min_off)
% Unpack the cell array
all_arts = [];
for j = 1:length(elec_arts)
    all_arts = [all_arts;elec_arts{j}];
end
all_arts = sort(all_arts);

final = [];
idx = 1;

while 1
    curr = all_arts(idx);
    
    % find the indices of artifacts close to this one (these are the
    % agreeing artifacts)
    close_idx = find(abs(all_arts-curr) < max_off);
    
    % if there are enough in agreement
    if length(close_idx) + 1 >= min_agree
        
         % Take the median
        med = round(median([curr;all_arts(close_idx)]));
        
        % If there isn't already one close to this time
        if isempty(final)
            final = [final;med];
        else
            if abs(final(end) - med) > min_off
                final = [final;med];
            end
        end
    end
    
    % whether it's enough or not, advance to the next
    idx = close_idx(end) + 1;
    
    if idx >= length(all_arts)
        break
    end
end

end

function final_arts = find_beat(arts,max_off,try_nums,goal_diff)
max_num_repeat = 31;
start = 1;
seq = nan;

for k = 1:length(try_nums)
    allowable_nums = try_nums(k);

    for a = start:length(arts)

        % candidate s (first time)
        s = arts(a);

        on_beat = a;

        % Loop through the other arts and see how many are within an allowable
        % distance
        for b = a+1:length(arts)

            new = arts(b);

            % If the two mod the goal diff aren't too far off
            if abs(mod(new-s,goal_diff)) < max_off && new-s > 100 && abs(new-s) < goal_diff*max_num_repeat

                if ~isempty(on_beat)
                    if abs(new-arts(on_beat(end))) < 100
                        continue
                    end
                end

                % Add it to the number that are on beat
                on_beat = [on_beat;b];

            end

            % break if too far apart
            if abs(new-s) > goal_diff*max_num_repeat
                break
            end

        end

        % Check how many are on beat
        if length(on_beat) >= min(allowable_nums)

            % If enough are on beat, then this is the correct sequence
            seq = on_beat;
            break

        end



        % If not enough on beat, try the next one

    end

    %if isnan(seq), error('Did not find it'); end


    if isnan(seq)
        %fprintf('Did not find it');
        continue
    else
        final_arts = seq;
        break

    end

end

if isnan(seq)
    final_arts = [];
end

end

