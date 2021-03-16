function keep_chs = get_chs_to_ignore(chLabels)

keep_chs = ones(length(chLabels),1);

for i = 1:length(chLabels)
    curr_label = chLabels{i};
    if contains(curr_label,'EKG') || contains(curr_label,'ekg') ...
            || contains(curr_label,'ECG') || contains(curr_label,'ecg')
        keep_chs(i) = 0; 
    end
    
    % remove RR channels too
    if contains(curr_label,'rate') || contains(curr_label,'rr') || contains(curr_label,'RR')
        keep_chs(i) = 0;
    end
    
    % remove scalp electrodes I guess
    if contains(curr_label,'C3') || contains(curr_label,'C4') || contains(curr_label,'CZ') ...
            || contains(curr_label,'FZ') || contains(curr_label,'ROC') || contains(curr_label,'LOC') ...
            || contains(curr_label,'C03') || contains(curr_label,'C04')
        keep_chs(i) = 0;
    end
end

keep_chs = logical(keep_chs);

end