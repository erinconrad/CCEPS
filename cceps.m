function cceps


%% Parameters
stim.pulse_width = 300e-3;
stim.train_duration = 30;
stim.stim_freq = 1;
stim.current = 3;
stim.fs = 512;

%% Get EEG data

%% Do pre-processing

%% Identify stimulation artifacts
artifact_idx = find_stim_artifacts(stim);

%% Identify separate electrode trials



%% Perform signal averaging over each electrode trial



end