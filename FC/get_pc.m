
%% Parameters
% data name to run (look for variable in workspace, otherwise use this
% default)
clearvars -except dataName
if ~exist('dataName','var')
    dataName = 'HUP212_CCEP';
end

time_to_measure = 30;
tw = 2; % 2 second calculations

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

%% Pull output mat
out = load([results_folder,'results_',dataName,'.mat']);
out = out.out;

research_start_time = clinical.start_time;

%% Find first closed relay time
periods = out.periods;
min_period = inf;
for i = 1:length(periods)
    if periods(i).start_time < min_period
        min_period = periods(i).start_time;
    end
end

%% Plan to look 1 minute before
if min_period - time_to_measure < research_start_time
    error('Not enough time between start and first stim');
end

pc_time = [min_period - time_to_measure min_period-1];

%% Get EEG data
data = download_eeg(dataName,loginname, pwfile,pc_time);
chLabels = data.chLabels(:,1);
% Remove leading zeros
chLabels = remove_leading_zeros(chLabels);
values = data.values;
fs = data.fs;

%% Ignore EKG channels, scalp channels
keep = get_chs_to_ignore(chLabels);
discard_chs = find(~keep);

%% Reject bad channels
[bad,details] = reject_bad_chs_2(values,chLabels,fs,[]);

%% Reduce data
keep_chs = 1:length(chLabels);
keep_chs(ismember(keep_chs,bad) | ismember(keep_chs,discard_chs)) = [];
keep_labels = chLabels(keep_chs);
values = values(:,keep_chs);

%% CAR
values = values - repmat(nanmean(values,2),1,size(values,2));

%% Notch and bandpass filter
values = do_filters(values,fs);

%% Get pc
pc = calc_pc(values,fs,tw);
pc = wrap_or_unwrap_adjacency_2(pc);

pout.details = details;
pout.chLabels = chLabels;
pout.bad = bad;
pout.discard_chs = discard_chs;
pout.pc = pc;
pout.name = out.name;
pout.keep_labels = keep_labels;

save([results_folder,sprintf('pc_%s',dataName)],'pout');