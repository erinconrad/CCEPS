function chLabels = remove_leading_zeros(chLabels)

for ich = 1:length(chLabels)
    label = chLabels{ich};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    if isempty(label_num_idx), continue; end

    label_non_num = label(1:label_num_idx-1);
    
    label_num = label(label_num_idx:end);
    
    % Remove leading zero
    if strcmp(label_num(1),'0')
        label_num(1) = [];
    end

    % fix for HUP266
    if length(label_num) >1 && strcmp(label_num(end-1),'0')
        label_num(end-1) = [];
    end
    
    label = [label_non_num,label_num];
    
    chLabels{ich} = label;
end

end