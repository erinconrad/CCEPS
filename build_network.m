function A= build_network(elecs,which,nchs,chLabels)

keep_chs = get_chs_to_ignore(chLabels);

% Should I normalize??
chs = 1:nchs;

A = nan(nchs,nchs);

for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    arr = elecs(ich).(which);
    
    % Add peak amplitudes to the array
    A(ich,:) = arr(:,1);
    
end

stim_chs = chs(nansum(A,2)>0);

if 1
    imagesc(A(stim_chs,keep_chs)')
    xticks(1:length(stim_chs))
    yticks(1:sum(keep_chs))
    xticklabels(chLabels(stim_chs))
    yticklabels(chLabels(keep_chs))
    
end

end