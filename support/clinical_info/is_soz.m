function A = is_soz(chLabels,clinical)

A = zeros(length(chLabels),1);
soz = clinical.clinical.soz_anatomic;
for i = 1:length(chLabels)
    if ismember(chLabels{i},soz)
        A(i) = 1;
    end
    
end

A = logical(A);

end