function [out,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,chs,chLabels)
    

if size(chLabels,1) ~=1
    chLabels = chLabels(:,1);
end

if isempty(chs)
    chs = 1:size(values,2);
end

% Initialize it as nans
out = nan(size(values,1),length(chs));
bipolar_labels = cell(length(chs),1);
bipolar_ch_pair = nan(length(chs),2);

for i = 1:length(chs)
    
    ch = chs(i);
    
    % Get electrode name
    label = chLabels{ch};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    if isempty(label_num_idx), continue; end
    label_non_num = label(1:label_num_idx-1);


    % get numerical portion
    label_num = str2num(label(label_num_idx:end));

    % see if there exists one higher
    label_num_higher = label_num + 1;
    higher_label = [label_non_num,sprintf('%d',label_num_higher)];
    if sum(strcmp(chLabels,higher_label)) > 0
        higher_ch = find(strcmp(chLabels,higher_label));
        
        out(:,i) = values(:,ch)-values(:,higher_ch);
        bipolar_labels{i} = [label,'-',higher_label];
        bipolar_ch_pair(i,:) = [ch,higher_ch];
        
    end
    
end

end