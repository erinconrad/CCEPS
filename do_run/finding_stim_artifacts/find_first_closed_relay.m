function time = find_first_closed_relay(ann)

time = nan;
for i = 1:length(ann.event)
    type = ann.event(i).type;
    if contains(type,'Closed relay')
        time = ann.event(i).start;
        break
    end
    
end

end