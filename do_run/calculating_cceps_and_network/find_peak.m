function [peak,peak_time] = find_peak(eeg,fs,stim_idx,peak_range,idx_before_stim)

%{
suggested values:
stim_idx = elecs(ich).stim_idx % not really a suggestion
peak_range = [50e-3 300e-3];
idx_before_stim = 30;
fs = stim.fs % not really a suggestion

%}

index_range = round(peak_range*fs + stim_idx);

nchs = size(eeg,2);
peak = nan(nchs,1);
peak_idx = nan(nchs,1);
for ich = 1:nchs
    values = eeg(:,ich);
    
    values_in_range = values(index_range(1):index_range(2));
    baseline = nanmedian(values(1:stim_idx-idx_before_stim));
    abs_diff = abs(values_in_range-baseline);
    
    [peak(ich),I] = max(abs_diff);
    peak_idx(ich) = (I + index_range(1) - 1);
    
    
    % Plot the peak
    if 0
        plot(values)
        hold on
        plot(peak_idx(ich),values(peak_idx(ich)),'o')
        plot(xlim,[baseline baseline],'r--')
        plot([stim_idx stim_idx],ylim,'r-');
        plot([index_range(1) index_range(1)],ylim,'k--')
        plot([index_range(2) index_range(2)],ylim,'k--')
        hold off
        pause
    end
    
end


peak_time = peak_idx/fs;

end