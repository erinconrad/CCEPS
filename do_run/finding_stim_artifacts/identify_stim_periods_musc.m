function stim =  identify_stim_periods_musc(event,chLabels,fs,times)

stim(length(chLabels)) = struct();

for i = 1:length(event)
    type = event(i).type;

    % see if it's a start stim annotation
    if contains(type,'Start stimulation', ...
            IgnoreCase=true)
        
        if event(i).start < times(1) || event(i).start > times(2)
            continue
        end

    end

end

end