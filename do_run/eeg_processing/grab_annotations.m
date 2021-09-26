function layer = grab_annotations(dataName, loginname, pwname)


%% Unchanging parameters
session = IEEGSession(dataName, loginname, pwname);

%% Get annotations
n_layers = length(session.data.annLayer);
if n_layers == 0
    layer = [];
else
    layer(n_layers) = struct();
end


for ai = 1:n_layers
    a=session.data.annLayer(ai).getEvents(0,1000);
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


end