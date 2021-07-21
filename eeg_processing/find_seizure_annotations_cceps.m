function [poss_sz_start,poss_sz_text] = find_seizure_annotations_cceps(layer)

poss_sz_text = {};
poss_sz_start = {};

n_layers = length(layer);
for l = 1:n_layers
    ann = layer(l).ann;

    n_anns = length(ann);
    for a = 1:n_anns

        n_events = length(ann(a).event);

        for i = 1:n_events


            description = ann(a).event(i).description;

            % search for seizure-y strings
            if contains(description,'seizure','IgnoreCase',true) || ...
                    contains(description,'sz','IgnoreCase',true) || ...
                    contains(description,'onset','IgnoreCase',true) || ...
                    contains(description,'UEO','IgnoreCase',true) || ...
                    contains(description,'EEC','IgnoreCase',true) 

                poss_sz_text = [poss_sz_text;description];
                %poss_sz_start = [poss_sz_start;floor(ann(a).event(i).start)];
                %
                poss_sz_start = [poss_sz_start;...
                    sprintf('%d',floor(ann(a).event(i).start))]; 
                %}

            end
        end

    end
end


end