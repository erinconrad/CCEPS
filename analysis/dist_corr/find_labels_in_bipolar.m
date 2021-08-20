function idx = find_labels_in_bipolar(bipolar_labels,other_labels)

nbip = length(bipolar_labels);
idx = nan(nbip,2);

for i = 1:nbip
    curr = bipolar_labels{i};
    if isempty(curr)
        continue;
    end
    C = strsplit(curr,'-');
    first = C{1};
    second = C{2};
    
    [~,fidx] = ismember(first,other_labels);
    if fidx ~=0
        idx(i,1) = fidx;
    end
    
    [~,sidx] = ismember(second,other_labels);
    if sidx ~=0
        idx(i,2) = sidx;
    end
end

if 0
% Test this by rebuilding bipolar labels from other labels
fake_bipolar_labels = cell(nbip,1);
for i = 1:nbip
    if isempty(bipolar_labels{i})
        continue
    end
    if isnan(idx(i,1)) || isnan(idx(i,2)), continue; end
    fake_bipolar_labels{i} = [other_labels{idx(i,1)},'-',other_labels{idx(i,2)}];
end


    table(fake_bipolar_labels,bipolar_labels)
end

end