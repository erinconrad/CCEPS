function show_stim(elecs,values,chLabels,which_elecs)


offset = 0;


first_art = inf;
last_art = 0;


if isempty(which_elecs)
    which_elecs = 1:length(chLabels);
end

if iscell(which_elecs)
new_which_elecs = zeros(length(which_elecs),1);
for i = 1:length(which_elecs)
    
    new_which_elecs(i) = find(strcmp(which_elecs{i},chLabels));
    
end

which_elecs = new_which_elecs;
end

stim_elecs = [];

% Get the samples of interest and non-empty indices
for ich = 1:length(which_elecs)
    
    if isempty(elecs(which_elecs(ich)).arts), continue; end
    
    stim_elecs = [stim_elecs;which_elecs(ich)];
    
    if elecs(which_elecs(ich)).arts(1,1) < first_art
        first_art = elecs(which_elecs(ich)).arts(1,1);
    end
    
    if elecs(which_elecs(ich)).arts(end,1) > last_art
        last_art = elecs(which_elecs(ich)).arts(end,1);
    end
    
end

ch_offsets = zeros(length(stim_elecs),1);
ch_bl = zeros(length(stim_elecs),1);

samples = first_art:last_art;
values = values(samples,:);

for ich = 1:length(stim_elecs)
    
    arts = elecs(stim_elecs(ich)).arts(:,1) - first_art+1;
    
    eeg = values(:,(stim_elecs(ich)));
    ch_offsets(ich) = offset;
    %ch_bl(ich) = -offset + max(elecs(stim_elecs(ich)).arts(:,3))-5e3;
    ch_bl(ich) = -offset + max(eeg)-5e3;
    plot(eeg-offset,'k');
    hold on
    plot(arts,eeg(arts)-offset,'bo')
    text(mean(arts),ch_bl(ich),sprintf('%s',chLabels{stim_elecs(ich)}),...
        'HorizontalAlignment','Center','Color','blue','fontsize',20)
    if ich<length(stim_elecs)
        offset = offset - (min(values(:,stim_elecs(ich))) - max(values(:,stim_elecs(ich+1))));
    end
    
end

end