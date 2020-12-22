function final_artifacts = identify_stim_chs(artifacts,stim)

%{
Approach:
Loop through each channel
    Within that channel, loop through each artifact
        The index channel is the candidate stim channel for that artifact
        Loop through every other channel
            Find the closest artifact in time to that 
            Compare sizes of stim artifact between channel i and j
            Take the larger one as the new candidate stim channel
        Procede in this fashion through all channels until we find the
        absolute stim channel for that artifact
    Procede in this fashion for all artifacts
Procede in this fashion for all channels
%}

pw = stim.pulse_width * stim.fs; % pulse width in samples

% Initialize the final list of artifacts
final_artifacts = [];

for ich = 1:length(artifacts)
    curr_ch = artifacts{ich};
    
    % Loop through all artifacts on that channel
    for a = 1:size(curr_ch,1)
        
        % set the candidate stim channel for artifact a to be ich
        index_artifact = curr_ch(a,:);
        index_time = index_artifact(1);
        index_amp = index_artifact(2);
        index_ch = ich; 
        
        % Loop through all other channels
        for jch = 1:length(artifacts)
            
            check_ch = artifacts{jch};
            
            % Find artifacts that occur within pwx2 of the index artifact
            close = abs(check_ch(:,1) -  index_time) < pw*2;
            
            % If more than one, throw an error
            if sum(close) > 1, error('what'); end
            
            % if empty, continue
            if sum(close) == 0, continue; end
            
            % See which stim artifact is larger
            if index_amp < check_ch(close,2)
                
                % if new one larger, set this as the index ch, time,
                % amplitude
                index_ch = jch;
                index_amp = check_ch(close,2);
                index_time = check_ch(close,1);
                
            end
            
        end
        
        % Once I have looped through all these secondary channels, I now
        % have the index channel for this artifact. I will compare it to
        % the list of final artifacts
        if isempty(final_artifacts)
            final_artifacts = [final_artifacts;index_time index_amp index_ch];
            continue;
        end
        
        close_final = abs(final_artifacts(:,1) - index_time) < pw *2;
        
        % If close_final has more than one entry, throw an error
        if sum(close_final) > 1, error('what'); end
        
        % if close_final empty, I will add this new artifact to the final
        % list
        if sum(close_final) == 0
            final_artifacts = [final_artifacts;index_time index_amp index_ch];
        else
            % If one entry, compare the amplitude
            comparison = final_artifacts(close_final,:);
            if comparison(2) < index_amp
               % replace the current entry with the new index
               final_artifacts(close_final,:) = [index_time index_amp index_ch];
            end
        end
        
        if sum(final_artifacts(:,1) == 0) > 0, error('what'); end
        % I have now updated the list of final artifacts based on this new
        % artifact and I can move onto the next artifact for that channel
        
    end
    
    % I have now checked all artifacts on a given channel and can move to
    % the next channel
end

% Now sort by time
final_artifacts = sortrows(final_artifacts);

end