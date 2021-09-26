function labels = justify_labels(labels,justification)


% Get max length
max_length = 0;
for i = 1:length(labels)
    curr_label = labels{i};
    if ischar(curr_label)
        word = curr_label;
        if length(word) > max_length
            max_length = length(word);
        end
    else
        for j = 1:length(curr_label)
            word = curr_label{j};
            if length(word) > max_length
                max_length = length(word);
            end
        end
    end

end

switch justification
    case 'right'
        
    % Loop through again and left pad everything
    for i = 1:length(labels)
        curr_label = labels{i};
        if ischar(curr_label)
            word = curr_label;
            pad = max_length - length(word);
            for k = 1:pad
                word = [' ',word];
            end
            labels{i} = word;
        else
            for j = 1:length(curr_label)
                word = curr_label{j};
                pad = max_length - length(word);
                for k = 1:pad
                    word = [' ',word];
                end
                curr_label{j} = word;
            end
            labels{i} = curr_label;
        end

    end
    
    case 'center'
        
    % Loop through again and left pad everything
    for i = 1:length(labels)
        curr_label = labels{i};
        if ~ischar(curr_label)
            max_word_length = 0;
            for j = 1:length(curr_label)
                word = curr_label{j};
                if length(word) > max_word_length
                    max_word_length = length(word);
                end
            end
            
            for j = 1:length(curr_label)
                word = curr_label{j};
                pad = max_word_length - length(word);
                for k = 1:pad
                    if mod(k,2) == 1
                        word = [word,' '];
                    else
                        word = [' ',word];
                    end
                end
                curr_label{j} = word;
            end
            labels{i} = curr_label;
        end

    end
    
    
    
    otherwise
   
end


%% Now convert to single string with new lines
for i = 1:length(labels)
    curr_label = labels{i};
    if isempty(curr_label), continue; end
    if ~ischar(curr_label)
        curr_label = sprintf('%s\\newline', curr_label{:});
        curr_label(end-7:end) = []; %remove last \newline
        labels{i} = curr_label;
    end
end
        
        
       

end