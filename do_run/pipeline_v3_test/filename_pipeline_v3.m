function out = filename_pipeline_v3(filename,login_name,pwfile,ignore_elecs)

%% Stimulation parameters
stim.train_duration = 30; % train duration (# stims) in seconds
stim.stim_freq = 1; % frequency (in Hz) of stimulation


%% Load ieeg file
server_count = 0;
% while loop in case of random server errors
while 1
    server_count = server_count + 1;
    if server_count > 50
        error('Too many server calls')

    end

    try session = IEEGSession(filename,login_name,pwfile);

    catch ME
        if contains(ME.message,'503') || contains(ME.message,'504') || ...
                contains(ME.message,'502') || contains(ME.message,'500')
            fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',server_count+1); 
            continue
        else
            ME
            error('Non-server error');
            
        end
        
    end

    break
end

%% Get metadata

% Get annotations
n_layers = length(session.data.annLayer);
all_anns = {};

for l = 1:n_layers
    curr_ann_count = 0;
    while 1 % ieeg only lets you pull 250 annotations at a time
        if curr_ann_count == 0
            a=session.data.annLayer(l).getEvents(0);
        else
            a=session.data.annLayer(l).getNextEvents(a(curr_ann_count));
        end
        curr_ann_count = length(a);
        for k = 1:length(a)
            all_anns(end+1,:) = ...
                {l, a(k).start/(1e6), a(k).stop/(1e6), a(k).type, a(k).description};
        end
        if isempty(a), break; end
    end
end
aT = cell2table(all_anns,'VariableNames',{'Layer_num','Start','Stop','Type','Description'});

% Get other info
fs = session.data.sampleRate;
chLabels = session.data.channelLabels(:,1);
chLabels = remove_leading_zeros(chLabels);
nchs = size(chLabels,1);
duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6);

% fill up stim info struct
stim.fs = fs;

%% Get the EEG data
% Get the start time of stim by finding the first closed relay annotation
% and looking 10 seconds before
index = startsWith(aT.Type, 'Closed relay') | startsWith(aT.Type,'Start Stimulation');
filteredStartTimes = aT.Start(index);
[minTime, idx] = min(filteredStartTimes); % Find the minimum start time from the filtered data
start_time = minTime - 10;
times = [start_time,duration]; % full
start_index = max(1,round(times(1)*fs));
end_index = round(times(2)*fs); 

% Get EEG data
values = zeros(end_index-start_index+1,nchs);
nchunks = min([80,nchs]);
for i = 1:nchunks
    attempt = 1;

    % Wrap data pulling attempts in a while loop
    while 1
        try
            values(:,floor(nchs/nchunks*(i-1))+1:min(floor(nchs/nchunks*i),nchs)) =...
                session.data.getvalues([start_index:end_index],...
                floor(nchs/nchunks*(i-1))+1:min(floor(nchs/nchunks*i),nchs));
            
            % break out of while loop
            break
            
            catch ME
            % If server error, try again (this is because there are frequent random
            % server errors).
            if contains(ME.message,'503') || contains(ME.message,'504') || ...
                    contains(ME.message,'502') ||  contains(ME.message,'500')
                attempt = attempt + 1;
                fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',attempt); 
            else
                ME
                error('Non-server error');
            end

        end
    
    end
end

% delete the ieeg session
session.delete;

%% Identify stim periods
% Get stim periods
periods = identify_stim_periods_v2(aT,chLabels,fs,times,ignore_elecs);

%% Get artifacts within periods
elecs = identify_artifacts_within_periods(periods,values,stim,chLabels);

%% Say which electrodes have stim and start times
[stim_elecs,stim_chs,stim_start_times] = return_stim_elecs_and_start_times(chLabels,elecs);

%% Do bipolar montage
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,[],chLabels);

%% Perform signal averaging (of bipolar montage values)
elecs = signal_average(bipolar_values,elecs,stim);

%% Aggregate info
out.filename = filename;
out.elecs = elecs;
out.other.stim = stim;
out.chLabels = chLabels;
out.bipolar_labels = bipolar_labels;
out.bipolar_ch_pair = bipolar_ch_pair;
out.other.periods = periods;
out.other.stim_elecs = stim_elecs;

%% Do chop filtering
out = chop_filtering(out);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);



%% Build a network
out = new_build_network(out);

end