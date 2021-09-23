function data = download_eeg(dataName, loginname, pwname, times)

% This is a tool to return information from a specified iEEG dataset

attempt = 1;

% Wrap data pulling attempts in a while loop
while 1
    
    try

        %% Unchanging parameters
        session = IEEGSession(dataName, loginname, pwname);
        fs = session.data.sampleRate;
        channelLabels = session.data.channelLabels;
        
        % break out of while loop
        break
        
    catch ME
        % If server error, try again (this is because there are frequent random
        % server errors).
        if contains(ME.message,'503') || contains(ME.message,'504') || ...
                contains(ME.message,'502') ||  contains(ME.message,'500')
            attempt = attempt + 1;
            fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',attempt); 
            session.delete
        else
            ME
            error('Non-server error');
        end
        
    end
    
end

%% Get annotations
n_layers = length(session.data.annLayer);
if n_layers == 0
    layer = [];
else
    layer(n_layers) = struct();
end



for ai = 1:n_layers
    a=session.data.annLayer(ai).getEvents(times(1),1000);
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

if isempty(times) % do whole duration
    duration = session.data.rawChannels(1).get_tsdetails.getDuration;
    duration = duration/(1e6);
    times(1) = 0;
    times(2) = duration;
end

start_index = max(1,round(times(1)*fs));
end_index = round(times(2)*fs); 

%values = session.data.getvalues([start_index:end_index],':');

% Break the number of channels in chunks
nchs = size(channelLabels,1);
%error('look');
values = zeros(end_index-start_index+1,nchs);
nchunks = 80;
for i = 1:nchunks
    values(:,floor(nchs/nchunks*(i-1))+1:min(floor(nchs/nchunks*i),nchs)) =...
        session.data.getvalues([start_index:end_index],...
        floor(nchs/nchunks*(i-1))+1:min(floor(nchs/nchunks*i),nchs));
end
%}

data.values = values;
data.chLabels = channelLabels;
data.fs = fs;
data.layer = layer;
        
        

session.delete;
clearvars -except data

end