function elecs = identify_diff_trials(artifacts,stim)

%{
Plan: build a structure arranged by electrode where I list the stim times
for each electrode and do some basic checks (like that I have the right
number of stims per electrode and that they are reasonably spaced)
%}

n_art = size(artifacts,1);
pw = stim.pulse_width * stim.fs;
goal_diff = stim.stim_freq * stim.fs;
max_off = pw*2;
allowable_nums = [stim.train_duration:-1:stim.train_duration-5];

% Get a list of unique channels stimulated
all_chs = unique(artifacts(:,3));

% Initialize structure
for ich = 1:length(all_chs)
    ch = all_chs(ich);
    elecs(ch).arts = [];
end


%% Make original structure
% Loop through the artifacts
for a = 1:n_art
    
    % Get the channel and time
    ch = artifacts(a,3);
    time = artifacts(a,1);
    
    % add the time to the artifact structure for the channel
    elecs(ch).arts = [elecs(ch).arts;time];
      
end

%% Remove potential artifacts that seem to be timed wrong
for ich = 1:length(elecs)
    if isempty(elecs(ich).arts), continue; end
    
    arts = elecs(ich).arts;
    on_beat = find_offbeat(arts,allowable_nums,goal_diff,max_off);
    
    elecs(ich).arts = arts(on_beat);
end

end