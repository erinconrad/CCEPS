function data = download_eeg(dataName,pwname,times)

% This is a tool to return information from a specified iEEG dataset


%% Unchanging parameters
loginname = 'erinconr';
session = IEEGSession(dataName, loginname, pwname);
fs = session.data.sampleRate;
channelLabels = session.data.channelLabels;

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
nchunks = 10;
for i = 1:nchunks
    values(:,floor(nchs/nchunks)*(i-1)+1:min(floor(nchs/nchunks)*i,nchs)) =...
        session.data.getvalues([start_index:end_index],...
        floor(nchs/nchunks)*(i-1)+1:min(floor(nchs/nchunks)*i,nchs));
end
%}

data.values = values;
data.chLabels = channelLabels;
data.fs = fs;

session.delete;
clearvars -except data

end