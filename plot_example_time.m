function plot_example_time(values,time,start_time,stim,chLabels,which_chs,artifacts,duration)

rel_time = time-start_time;
samples = max(1,round(rel_time*stim.fs)):max(1,round(rel_time*stim.fs)) + round(duration*stim.fs);

values = values(samples,:);
offset = 0;

ch_offsets = zeros(size(values,2),1);
ch_bl = zeros(size(values,2),1);

figure
for ich = 1:length(which_chs)%1:size(values,2)

    eeg = values(:,which_chs(ich));
    times = linspace(0,duration,length(samples));
    
    ch_offsets(ich) = offset;
    ch_bl(ich) = -offset + median(values(:,which_chs(ich)));
    plot(times,eeg-offset,'k');
    hold on
    plot(artifacts{which_chs(ich)}(:,1)/stim.fs-rel_time,values(artifacts{which_chs(ich)}(:,1)),'o')
    text(duration+0.05,ch_bl(ich),sprintf('%s',chLabels{which_chs(ich)}))
    if ich<length(which_chs)
        offset = offset - (min(values(:,which_chs(ich))) - max(values(:,which_chs(ich+1))));
    end
    
    
end

end