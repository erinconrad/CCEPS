%{
More artifact rejection - if big dc change???
%}

%% Parameters
% data name to run (look for variable in workspace, otherwise use this
% default)
clearvars -except dataName
if ~exist('dataName','var')
    dataName = 'HUP212_CCEP';
end

% which waveform to plot
wav = 'N1';
how_to_normalize = 0;

% Stimulation parameters
stim.pulse_width = 300e-6; % pulse width in seconds
stim.train_duration = 30; % train duration (# stims) in seconds
stim.stim_freq = 1; % frequency (in Hz) of stimulation

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

%% Pull clinical info
clinical = pull_clinical_info(dataName);
stim.current = clinical.current;
times_in = clinical.time_breaks;
if isempty(times_in)
    nloops = 1;
else
    nloops = length(times_in)-1;
end


%% Get EEG data

times = [clinical.start_time,clinical.end_time];

%times = [clinical.start_time,clinical.end_time];

% Load output file if it already exists
%{
if exist([results_folder,sprintf('results_%s.mat',dataName)],'file') ~= 0
    load([results_folder,sprintf('results_%s.mat',dataName)]); % loads a structure called 'out'
else
    out = [];
end
%}
tic
data = download_eeg(dataName,loginname, pwfile,times);
chLabels = data.chLabels(:,1);
% Remove leading zeros
chLabels = remove_leading_zeros(chLabels);
values = data.values;
stim.fs = data.fs;
t = toc;
fprintf('\nGot data in %1.1f minutes\n',t/60);

%% Get anatomic locations
ana = anatomic_location(chLabels,clinical,1);

%% Get stim periods
periods = identify_stim_periods(data.layer.ann.event,chLabels,stim.fs,times);

%% Get artifacts within periods
elecs = identify_artifacts_within_periods(periods,values,stim,chLabels);

%% Say which electrodes have stim
%stim_chs = true_stim(dataName);
stim_chs = clinical.stim_electrodes;
[extra,missing,elecs] = find_missing_chs(elecs,stim_chs,chLabels);

%% Reject bad channels
%[bad,details] = reject_bad_chs(values,chLabels,stim.fs,elecs);
bad = [];
details = [];

%% Do bipolar montage
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,[],chLabels);


%% Perform signal averaging
elecs = signal_average(bipolar_values,elecs,stim,chLabels,0);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);

%% Merge old and new elecs
%elecs = merge_elecs(out,elecs,chLabels);

%% Save info
%
out.name = dataName;
out.elecs = elecs;
out.stim = stim;
out.chLabels = chLabels;
out.bipolar_labels = bipolar_labels;
out.bipolar_ch_pair = bipolar_ch_pair;
out.waveform = wav;
out.how_to_normalize = how_to_normalize;
out.ana = ana;
out.extra = extra;
out.missing = missing;
out.clinical = clinical;
out.bad = bad;
out.bad_details = details;
out.periods = periods;
%}

save([results_folder,sprintf('results_%s',dataName)],'out');


%% Build a network
[A,ch_info] = build_network(out,0);
%[A,ch_info] = build_network(elecs,stim,wav,nchs,chLabels,ana,how_to_normalize,0);
out.A = A;
out.ch_info = ch_info;
save([results_folder,sprintf('results_%s',dataName)],'out');
