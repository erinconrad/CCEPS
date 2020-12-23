function cceps


%% Parameters
stim.pulse_width = 300e-6;
stim.train_duration = 30;
stim.stim_freq = 1;
stim.current = 3;
stim.fs = 512;


%% Get EEG data
values = make_fake_eeg(stim);


%% Do pre-processing

%% Identify stimulation artifacts
% Loop over EEG
nchs = size(values,2);
artifacts = cell(nchs,1);
for ich = 1:nchs
    eeg = values(:,ich);
    out = find_stim_artifacts(stim,eeg);
    
    artifacts{ich} = out;
end

%% Narrow down the list of stimulation artifacts to just one channel each
final_artifacts = identify_stim_chs(artifacts,stim);

%% Identify separate electrode trials
elecs = identify_diff_trials(final_artifacts,stim);

%% Perform signal averaging
elecs = signal_average(values,elecs,stim);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);

%% Build a network
A = build_network(elecs,'n1',nchs);


end