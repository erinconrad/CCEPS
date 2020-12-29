function A= build_network(elecs,which,nchs,chLabels)

% Should I normalize??
chs = 1:nchs;

A = nan(nchs,nchs);

for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    arr = elecs(ich).(which);
    
    % Add peak amplitudes to the array
    A(ich,:) = arr(:,1);
    
end

stim_chs = chs(~isnan(sum(A,2)));

if 1
    imagesc(A(stim_chs,:))
    yticks(1:length(stim_chs))
    xticks(chs)
    yticklabels(chLabels(stim_chs))
    xticklabels(chLabels(chs))
    
end

end