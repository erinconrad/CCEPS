function out = run_uab_pipeline(data_struct)

%% Get parameters
stim.train_duration = 30;
stim.stim_freq = 1;
stim.fs = data_struct.sampling_rate;
chLabels = data_struct.electrode_labels;
filename = data_struct.name;

data = data_struct.data;

%% Get values and periods
[values,periods] = make_fake_continuous_data(data,chLabels,stim.fs);

%% Get artifacts within periods
elecs = identify_artifacts_within_periods(periods,values,stim,chLabels);

%% Say which electrodes have stim and start times
[stim_elecs,stim_chs,stim_start_times] = return_stim_elecs_and_start_times(chLabels,elecs);

%% Do bipolar montage
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,[],chLabels);

%% Perform signal averaging (of bipolar montage values)
elecs = signal_average(bipolar_values,elecs,stim);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);

%% Aggregate info
out.name = filename;
out.filename = filename;
out.elecs = elecs;
out.other.stim = stim;
out.chLabels = chLabels;
out.bipolar_labels = bipolar_labels;
out.bipolar_ch_pair = bipolar_ch_pair;
out.other.periods = periods;
out.other.stim_elecs = stim_elecs;

%% Build a network
out = new_build_network(out);


end