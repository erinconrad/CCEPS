%{
More artifact rejection - if big dc change???

Add Caren's stuff
%}

%% Parameters
% data name to run (look for variable in workspace, otherwise use this
% default)
if ~exist('dataName','var')
    dataName = 'CHOP_CCEPs';
end

% Get from edf?
do_edf = 0;
edf_path = '../../data/CHOP011shortclip.EDF';

% Use annotations?
use_annotations = 0;

% Missing clinical?
missing_clinical = 0;

% which waveform to plot
wav = 'N1';
how_to_normalize = 0;


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

%% Pull clinical info
if ~missing_clinical
    clinical = pull_clinical_info(dataName);
else
    clinical = [];
end



%% Get EEG data
if do_edf
    data = get_edf(edf_path,[]);
    chLabels = data.chLabels;
else
    tic
    if strcmp(clinical.end_time,'end')
        % Get file duration
        session = IEEGSession(dataName,loginname, pwfile);
        duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6); %convert from microseconds
        session.delete;
        times = [clinical.start_time,duration];
    else
        times = [clinical.start_time,clinical.end_time];
    end
    data = download_eeg(dataName,loginname, pwfile,times);
    t = toc;
    fprintf('\nGot data in %1.1f minutes\n',t/60);
    chLabels = data.chLabels(:,1);
end

% Remove leading zeros
chLabels = remove_leading_zeros(chLabels);
values = data.values;
stim.fs = data.fs;

%% Get anatomic locations
if ~missing_clinical
    ana = anatomic_location(chLabels,clinical,1);
else
    ana = [];
end

if use_annotations
    %% Get stim periods
    periods = identify_stim_periods(data.layer.ann.event,chLabels,stim.fs,times);

    %% Get artifacts within periods
    elecs = identify_artifacts_within_periods(periods,values,stim,chLabels);
else
    
    % Do old way to get artifacts
    periods = nan;
    
    %% Identify stimulation artifacts
    % Loop over EEG
    nchs = size(values,2);
    artifacts = cell(nchs,1);
    for ich = 1:nchs
        artifacts{ich} = find_stim_artifacts(stim,values(:,ich));
        %artifacts{ich} = find_stim_artifacts(stim,bipolar_values(:,ich),values(:,ich));
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
    elecs = define_ch(artifacts,stim,chLabels);
    
end

%% Say which electrodes have stim
if ~missing_clinical
    stim_chs = clinical.stim_electrodes;
    stim_current = clinical.current;
    [extra,missing,elecs] = find_missing_chs(elecs,stim_chs,stim_current,chLabels);
else
    extra = nan;
    missing = nan;
end

%% Do bipolar montage
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,[],chLabels);

%% Perform signal averaging
elecs = signal_average(bipolar_values,elecs,stim,chLabels,0);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);

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
out.bad = [];
out.bad_details = [];
out.periods = periods;
%}

outdir = [results_folder,'out_files/'];
if ~exist(outdir,'dir')
    mkdir(outdir)
end
save([outdir,sprintf('results_%s',dataName)],'out');


%% Build a network
[A,ch_info] = build_network(out,0);
%[A,ch_info] = build_network(elecs,stim,wav,nchs,chLabels,ana,how_to_normalize,0);
out.A = A;
out.ch_info = ch_info;
save([outdir,sprintf('results_%s',dataName)],'out');
