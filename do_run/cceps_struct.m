%{
To dos
1) Add code to remove bad channels in this step (currently only doing in
the FC code)
2) Ways to allow for repeated stims?
%}
function out = cceps_struct(pt,p)

%% Parameters
% which waveform to plot (N1 is standard)
wav = 'N1';
how_to_normalize = 0; % should probably keep 0


%% Probably always the same
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

%% Get start time and dataname
dataName = pt(p).ccep.file.name;
start_time = find_first_closed_relay(pt(p).ccep.file.ann)-10;

%% Get EEG data
% Get data from IEEG (the main way)
tic
% Get file duration
session = IEEGSession(dataName,loginname, pwfile);
duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6); %convert from microseconds
session.delete;
times = [start_time,duration];

data = download_eeg(dataName,loginname, pwfile,times);
t = toc;
fprintf('\nGot data in %1.1f minutes\n',t/60);
chLabels = data.chLabels(:,1);

% Remove leading zeros
chLabels = remove_leading_zeros(chLabels);
values = data.values;
stim.fs = data.fs;

%% Get stim periods
periods = identify_stim_periods(data.layer.ann.event,chLabels,stim.fs,times);


%% Get artifacts within periods
elecs = identify_artifacts_within_periods(periods,values,stim,chLabels);

%% Say which electrodes have stim
extra = nan;
missing = nan;

%% Do bipolar montage
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,[],chLabels);

%% Perform signal averaging (of bipolar montage values)
elecs = signal_average(bipolar_values,elecs,stim);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);

%% Save info
out.name = dataName;
out.elecs = elecs;
out.stim = stim;
out.chLabels = chLabels;
out.bipolar_labels = bipolar_labels;
out.bipolar_ch_pair = bipolar_ch_pair;
out.waveform = wav;
out.how_to_normalize = how_to_normalize;
out.extra = extra;
out.missing = missing;
out.bad = [];
out.bad_details = [];
out.periods = periods;


outdir = [results_folder,'out_files/'];
if ~exist(outdir,'dir')
    mkdir(outdir)
end
save([outdir,sprintf('results_%s',dataName)],'out');


%% Build a network
[A,ch_info,details] = new_build_network(out,0);
out.A = A;
out.ch_info = ch_info;
out.details = details;
save([outdir,sprintf('results_%s',dataName)],'out');

end
