function elecs = merge_elecs(out,elecs,chLabels)

nchs = length(chLabels);

if ~isempty(out)
    
if isfield(out,'elecs')
    
    if ~isempty(out.elecs)
        for ich = 1:nchs
            if ~isempty(out.elecs(ich).arts)
                if ~isempty(elecs(ich).arts)
                    fprintf('\nWarning, detected stim on same channel %s two different times. Using new one.\n',chLabels{ich});
                else
                    elecs(ich) = out.elecs(ich);
                end
                
            end
            
        end
        
    end
    
end
    
end

end