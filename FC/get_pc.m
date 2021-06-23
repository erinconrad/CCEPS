
%% Parameters
% data name to run (look for variable in workspace, otherwise use this
% default)
clearvars -except dataName
if ~exist('dataName','var')
    dataName = 'CHOP_CCEPs';
end

if strcmp(dataName,'CHOP_CCEPs')
    pc_time = [9346.09 9346.09+2];
else
    pc_time = [];
end

rm_vis = 0;
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
out = load([results_folder,'out_files/results_',dataName,'.mat']);
out = out.out;


if ~isempty(clinical.main_ieeg_file)
    ieeg_name = clinical.main_ieeg_file;
    research_start_time = clinical.stim_time_main_file;
    pc_time = [research_start_time - 60*5,research_start_time-1]; % five minutes back
else
    ieeg_name = dataName;
    research_start_time = clinical.start_time;
    
    if isempty(pc_time)
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
    end
    
end
    
%{

%}

%% Get EEG data
data = download_eeg(ieeg_name,loginname, pwfile,pc_time);
chLabels = data.chLabels(:,1);
% Remove leading zeros
chLabels = remove_leading_zeros(chLabels);
values = data.values;
fs = data.fs;

%% Bipolar
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage(values,1:length(chLabels),chLabels);

%% Ignore EKG channels, scalp channels
keep = get_chs_to_ignore(chLabels);
discard_chs = find(~keep);

%% Reject bad channels
% Automated
[bad,details] = reject_bad_chs_2(values,chLabels,fs,[]);

if iscell(clinical.visually_bad_chs)
    bad_visual = find(ismember(chLabels,clinical.visually_bad_chs));

    excess_auto = sum(~ismember(bad,bad_visual));
    excess_visual = sum(~ismember(bad_visual,bad));
    fprintf('\nFound %d unique bad visually and %d unique bad automatically\n',...
        excess_visual,excess_auto);
    
    if rm_vis
        bad = unique([bad;bad_visual]);
    end
end



%% Reduce data
keep_chs = 1:length(chLabels);
keep_chs(ismember(keep_chs,bad) | ismember(keep_chs,discard_chs)) = [];
keep_labels = chLabels(keep_chs);
values = values(:,keep_chs);
bipolar_labels = bipolar_labels(keep_chs);
bipolar_ch_pair = bipolar_ch_pair(keep_chs,:);
bipolar_values = bipolar_values(:,keep_chs);

%% Get CAR and machine ref as well
% CAR
car_values = values - repmat(nanmean(values,2),1,size(values,2));

% Machine ref (do nothing)
machine_values = values;

%% Notch and bandpass filter
machine_values = do_filters(machine_values,fs);
car_values = do_filters(car_values,fs);
bipolar_values = do_filters(bipolar_values,fs);

%% Get pc
machine_pc = calc_pc(machine_values,fs,tw);
machine_pc = wrap_or_unwrap_adjacency_2(machine_pc);

bipolar_pc = calc_pc(bipolar_values,fs,tw);
bipolar_pc = wrap_or_unwrap_adjacency_2(bipolar_pc);

car_pc = calc_pc(car_values,fs,tw);
car_pc = wrap_or_unwrap_adjacency_2(car_pc);

pout.details = details;
pout.chLabels = chLabels;
pout.bad = bad;
pout.discard_chs = discard_chs;
pout.bipolar_pc = bipolar_pc;
pout.machine_pc = machine_pc;
pout.car_pc = car_pc;
pout.name = out.name;
pout.keep_labels = keep_labels;
pout.bipolar_ch_pair = bipolar_ch_pair;
pout.bipolar_labels = bipolar_labels;

outdir = [results_folder,'out_files/'];
if ~exist(outdir,'dir')
    mkdir(outdir)
end
save([outdir,sprintf('pc_%s',dataName)],'pout');