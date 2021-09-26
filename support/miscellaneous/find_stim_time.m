function find_stim_time(dataName,loginname,pwname)


session = IEEGSession(dataName, loginname, pwname);
fs = session.data.sampleRate;
channelLabels = session.data.channelLabels;

%% Get annotations
n_layers = length(session.data.annLayer);
if n_layers == 0
    layer = [];
else
    layer(n_layers) = struct();
end



for ai = 1:n_layers
    a=session.data.annLayer(ai).getEvents(1,1000);
    n_ann = length(a);
    for i = 1:n_ann
        event(i).start = a(i).start/(1e6);
        event(i).stop = a(i).stop/(1e6); % convert from microseconds
        event(i).type = a(i).type;
        event(i).description = a(i).description;
    end
    ann.event = event;
    ann.name = session.data.annLayer(ai).name;
    layer(ai).ann = ann;
end

%% Hunt for stim stuff
for ai = 1:n_layers
    for i = 1:length(layer(ai).ann.event)
        if contains(layer(ai).ann.event(i).type,'stim','ignorecase',true) ...
                || contains(layer(ai).ann.event(i).type,'cceps','ignorecase',true)
            layer(ai).ann.event(i)
        end
    end
end

end