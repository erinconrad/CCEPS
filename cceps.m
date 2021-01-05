

%{

fix timing in get waveforms

play around with waveform detector

consider additional processing (like a notch filter)

%}

%% Parameters
% ieeg parameters
dataName = 'HUP212_CCEP';%'HUP211_CCEP'
pwfile = '/Users/erinconrad/Desktop/research/gen_tools/eri_ieeglogin.bin';
times = [18893 21999];%[12946 13592]; % times in seconds surrounding the stim session

% Stimulation parameters
stim.pulse_width = 300e-6; % pulse width in seconds
stim.train_duration = 30; % train duration (# stims) in seconds
stim.stim_freq = 1; % frequency (in Hz) of stimulation
stim.current = 3; % stimulation current 

% Plotting prep
mydir  = pwd;
idcs   = strfind(mydir,'/');
newdir = mydir(1:idcs(end)-1);

%% Get EEG data
data = download_eeg(dataName,pwfile,times);
values = data.values;
stim.fs = data.fs;
fprintf('\nGot data\n');

%% Get anatomic locations
ana = anatomic_location(dataName,data.chLabels);

%% Identify stimulation artifacts
% Loop over EEG
nchs = size(values,2);
artifacts = cell(nchs,1);
for ich = 1:nchs
    artifacts{ich} = find_stim_artifacts(stim,values(:,ich));
end
old_artifacts = artifacts;

%% Remove those that are not on beat
for ich = 1:nchs
    if isempty(old_artifacts{ich})
        continue;
    else
        on_beat = find_offbeat(old_artifacts{ich}(:,1),stim);
    end
    if ~isempty(on_beat)
        artifacts{ich} = [old_artifacts{ich}(on_beat(:,1),:),on_beat(:,2)]; 
    else
        artifacts{ich} = [];
    end
end


%% Narrow down the list of stimulation artifacts to just one channel each
%elecs = alt_find_stim_chs(artifacts,stim,data.chLabels);
elecs = define_ch(artifacts,stim,data.chLabels);


%% Say which electrodes have stim
stim_chs = true_stim(dataName);
[extra,missing] = find_missing_chs(elecs,stim_chs,data.chLabels);

%% Perform signal averaging
elecs = signal_average(values,elecs,stim);

%% Plot a long view of the stim and the relevant electrodes
%show_stim(elecs,values,data.chLabels,[])

%% Plot the average for an example
%show_avg(elecs,stim,data.chLabels,'LH06','LA10')

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim,data.chLabels);

%% Build a network
[A,ch_info] = build_network(elecs,stim,'n1',nchs,data.chLabels,ana,1,1);

