function [coords_bipolar,bipolar_labels,bipolar_ch_pair] = BIPOLAR_MONTAGE_COORDS(coords,chLabels)
    
% this function borrowed from eeg_processing/bipolar_montage.m
%
% INPUTS:
% coords: Nx3 matrix of 3D coordinates for N electrodes
% chLabels: Nx1 cell of electrode names
% 
% OUTPUTS:
% coords: Nx3 matrix of 3D coordinates for each electrode's corresponding
% bipolar pair, computed as the midpoint between the two electrodes in
% euclidean space

chs = 1:length(chLabels);

% Initialize it as nans
coords_bipolar = nan(size(coords));
bipolar_labels = cell(length(chs),1);
bipolar_ch_pair = nan(length(chs),2);

for i = 1:length(chs)
    
    ch = chs(i);
    
    % Get electrode name
    label = chLabels{ch};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    label_non_num = label(1:label_num_idx-1);

    % get numerical portion
    label_num = str2num(label(label_num_idx:end));

    % see if there exists one higher
    label_num_higher = label_num + 1;
    higher_label = [label_non_num,sprintf('%d',label_num_higher)];
    if sum(strcmp(chLabels(:,1),higher_label)) > 0
        higher_ch = find(strcmp(chLabels(:,1),higher_label));
        
        coords_bipolar(i,:) = (coords(ch,:) + coords(higher_ch,:))/2;
        bipolar_labels{i} = [label,'-',higher_label];
        bipolar_ch_pair(i,:) = [ch,higher_ch];
        
    end
    
end

end