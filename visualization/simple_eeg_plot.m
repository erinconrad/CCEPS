function simple_eeg_plot(values,chLabels)

offset = 0;

figure
for ich = 1:size(values,2)

    if sum(~isnan(values(:,ich))) ~=0
        eeg = values(:,(ich));

        plot(eeg-offset,'k');
        hold on
        text(length(eeg)+0.05,-offset + nanmedian(eeg),sprintf('%s',chLabels{(ich)}))
        last_min = min(values(:,ich));
    end
    if ich<size(values,2)
        %offset = offset - (min(values(:,(ich))) - max(values(:,(ich+1))));
        if ~isnan(max(values(:,ich+1))) && ~isnan(last_min)
            offset = offset - (last_min - max(values(:,ich+1)));
        end
    end
    
    
end


end