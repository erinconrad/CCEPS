function ana = anatomic_location(chLabels,clinical,abbreviate)

if isempty(clinical)
    ana = [];
    return
end

ana = cell(length(chLabels),1);


for ich = 1:length(chLabels)
    label = chLabels{ich};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    if isempty(label_num_idx), continue; end

    label_non_num = label(1:label_num_idx-1);

    found_it = 0;
    map = clinical.map;
    % Loop through the map and find the corresponding anatomical target
    for m = 1:length(map)
        elec = map(m).electrode;
        if strcmp(elec,label_non_num)
            ana{ich} = map(m).target;
            found_it = 1;
            break
        end
    end
    
       
end

if abbreviate == 1
    ana = get_abbreviations(ana);
    
end



end