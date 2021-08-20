function bi_locs = get_bipolar_locs(idx,locs)

nchs = size(idx,1);
bi_locs = nan(nchs,3);

for i = 1:nchs
    curr_idx = idx(i,:); % the indices in locs of the two bipolar chs
    if any(isnan(curr_idx)), continue; end
    
    % Take the mean of the positions of those 2 chs
    mid = mean(locs(curr_idx,:),1);
    
    bi_locs(i,:) = mid;
end

end