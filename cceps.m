function cceps


%{
Should add something to remove cases in which the amplitude around the stim
is too high

play around with waveform detector

%}

%% Parameters
% ieeg parameters
dataName = 'HUP211_CCEP';
pwfile = '/Users/erinconrad/Desktop/research/gen_tools/eri_ieeglogin.bin';
times = [12946 13592];%[18893 21999];%[12946 13592]; % if empty, returns full duration
ex_time = 13486;

% Stimulation parameters
stim.pulse_width = 300e-6;
stim.train_duration = 30;
stim.stim_freq = 1;
stim.current = 3;
stim.fs = 512;



%% Get EEG data
%values = make_fake_eeg(stim);

data = download_eeg(dataName,pwfile,times);
values = data.values;
if stim.fs ~= data.fs
   fprintf('\nWarning, fs is different, changing\n'); 
   stim.fs = data.fs;
end
fprintf('\nGot data\n');

%% plot example time
%plot_example_time(values,ex_time,times(1),stim,data.chLabels,1:length(data.chLabels))

%% Do pre-processing??

%% Identify stimulation artifacts
% Loop over EEG
nchs = size(values,2);
artifacts = cell(nchs,1);
for ich = 1:nchs
    eeg = values(:,ich);
    artifacts{ich} = find_stim_artifacts(stim,eeg);
end
for ich = 1:nchs
    if isempty(artifacts{ich})
        continue;
    else
        on_beat = find_offbeat(artifacts{ich}(:,1),stim);
    end
    if ~isempty(on_beat)
        artifacts{ich} = [artifacts{ich}(on_beat(:,1),:),on_beat(:,2)]; 
    else
        artifacts{ich} = [];
    end
    
    
end


%% Narrow down the list of stimulation artifacts to just one channel each
%final_artifacts = identify_stim_chs(artifacts,stim);

elecs = alt_find_stim_chs(artifacts,stim,data.chLabels);
%% Identify separate electrode trials
%elecs = identify_diff_trials(final_artifacts,stim);

%% Perform signal averaging
elecs = signal_average(values,elecs,stim);

%% Say which electrodes have stim
for i = 1:length(elecs)
    if ~isempty(elecs(i).arts)
        fprintf('%s (elec %d) has stim.\n',data.chLabels{i},i);
    end
end

%% Plot a long view of the stim and the relevant electrodes
show_stim(elecs,values,data.chLabels,[])

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim,data.chLabels);

%% Build a network
A = build_network(elecs,'n1',nchs,data.chLabels);


end