function elecs = define_ch(artifacts,stim,chLabels)

%{
The idea behind this function is that sometimes the stimulation saturates
the amplifier for an extended period of time, making it difficult to
identify the timing of the stims. To solve this, I will group sequences
from different channels if they are within the same second or so. I will
then decide the correct beat based on the majority of channels. I will then
find which channel the stim was on based on the highest amplitude
%}

%% Parameters
time_diff_seq = 10*stim.fs; % how close should the first stim be to be grouped in the same group 
discrepancy_bipolar = 0.50;

%% Fill in missing elecs
for ich = 1:length(chLabels)
    elecs(ich).arts = [];
end

%% Group similarly timed stims
group = {};

% Loop through electrode sequences
for ich = 1:length(artifacts)
    
    % Skip if empty
    if isempty(artifacts{ich}), continue; end
    
    
    curr_ch = artifacts{ich};
    
    nseq = max(unique(curr_ch(:,4)));
    for s = 1:nseq
        
      curr_seq = curr_ch(curr_ch(:,4) == s,:);
      curr_seq = [curr_seq,repmat(ich,size(curr_seq,1),1)];
      first_time_seq = curr_seq(1,1);

      added_to_group = 0;
      % Now loop through the groups
      for j = 1:length(group)
            
            % Compare the first artifact in the sequence to the first
            % artifact in the first member of the group
            curr_group = group{j};
            first_member = curr_group{1};
            first_time_group = first_member(1,1);
             
            % If they're close enough in time
            if abs(first_time_group - first_time_seq) < time_diff_seq
                % Add it to the group
                group{j} = [group{j};curr_seq];
                added_to_group = 1;
                break
            end
        
      end
      
      if added_to_group == 0
        
          % Make a new group
          curr_group = {};
          curr_group{end+1} = curr_seq;
          group{end+1} = curr_group;
      end
      
    end
end

%% Now, for each group, determine the timing of the artifacts and stim ch
% loop through each group
for i = 1:length(group)
    member = group{i};
    if isempty(member), continue; end
    % make an array with times
    times = [];
    amps = [];
    chs = [];
    
    % Should have at least 2 channels involved to be a legit group
    if length(member) == 1, continue; end
    
    % Loop through members of group and add times and amps to array
    for j = 1:length(member)
        curr_times = member{j}(:,1);
        curr_amps = member{j}(:,2);
        curr_ch = member{j}(1,5);
        % Fix for non-30 times
        if length(curr_times) < 30
            curr_times = [curr_times;repmat(curr_times(end),30-length(curr_times),1)];
        elseif length(curr_times) > 30
            curr_times(end-(length(curr_times)-30)+1:end) = [];
        end
        old_times = times;
        times = [times,curr_times];
        amps = [amps,sum(curr_amps)];
        chs = [chs,curr_ch];
    end
    
    
    % Get the mode times - this will be our stim times
    mode_times = mode(times,2); 
    
    %
    
    % Now get the two highest amplitude channels - one of these will be our
    % channel
    [amps,I] = sort(amps,'descend');
    
    if length(I) == 1
        elecs(chs(I(1))).arts = mode_times;
        continue; 
    end
    
    two_highest = chs(I(1:2));
    
    % If similar in amplitude, suspect these are the two channels
    % stimulated in a bipolar fashion. Pick the lowest numbered one.
   % if amps(2)/amps(1) > discrepancy_bipolar % if they're close in amplitude
        % In this case, assign it to the lowest numbered
        % one
        curr_label = chLabels{two_highest(1)};
        test_label = chLabels{two_highest(2)};

        % derive the number
        curr_elec_num = regexp(curr_label,'\d');
        test_elec_num = regexp(test_label,'\d');
        
        if isempty(curr_elec_num) % if highest is non-standard, assign to second highest
            elecs(chs(I(2))).arts = mode_times;
            continue;
        elseif isempty(test_elec_num)
            elecs(chs(I(1))).arts = mode_times;
            continue;
        end
        
        curr_elec_label = curr_label(1:curr_elec_num-1);
        curr_elec_num = str2num(curr_label(curr_elec_num(1):end));


        test_elec_label = test_label(1:test_elec_num-1);
        test_elec_num = str2num(test_label(test_elec_num(1):end));
        
        if test_elec_num == curr_elec_num - 1 && strcmp(curr_elec_label,test_elec_label) % jch lower, keep that one
            elecs(chs(I(2))).arts = mode_times;
        elseif curr_elec_num == test_elec_num - 1 && strcmp(curr_elec_label,test_elec_label) % ich lower, keep that one
            elecs(chs(I(1))).arts = mode_times;
        else % keep higher amplitude one
            elecs(chs(I(1))).arts = mode_times;
            
        end
                        
   % else
   %     elecs(chs(I(1))).arts = mode_times;
   % end
        
end



end