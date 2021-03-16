function [extra,missing,elecs] = find_missing_chs(elecs,true_stim,chLabels)

missing = [];
extra = [];

% Find extra and missing channels
for i = 1:length(elecs)
    ch = chLabels{i};
    
    % was this stimulated?
    got_stim = sum(strcmp(ch,true_stim));
    
    if got_stim == 1
        % Did I find it?
        if isempty(elecs(i).arts)
            missing = [missing;i];
        end
    else
        % Did I mistakenly find it?
        if ~isempty(elecs(i).arts)
            extra = [extra;i];
            
            % Remove it
           % elecs(i).arts = [];
        end
    end
    
    
    
end

fprintf('\nMistakenly found stim on:\n')
for i = 1:length(extra)
    fprintf('%s\n',chLabels{extra(i)});
end
%fprintf('\nI removed these.\n')

fprintf('\nMissed stim on:\n')
for i = 1:length(missing)
    fprintf('%s\n',chLabels{missing(i)});
end
end