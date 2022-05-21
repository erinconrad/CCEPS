function out = get_edf(fname,which_elec)

%% Load data as timetable (what)
info = edfinfo(fname);
annotations = info.Annotations;

%% Get basic info
samples_per_time = info.NumSamples(1,1);
num_samples = samples_per_time*info.NumDataRecords;
fs = info.NumSamples(1,1)/seconds(info.DataRecordDuration);

%% Get channel labels (includes some things that are not channels)
signal_labels = info.SignalLabels;
nsignals = length(signal_labels);

%% Initialize values
values = nan(num_samples,nsignals);

% Separately call edfread for each signal
for is = 1:nsignals
    curr_signal = signal_labels(is);
    
    % Get timetable for that signal
    T = edfread(fname,'SelectedSignals',curr_signal);
    
    
    % Get variable name (may be changed once put into table)
    Var1 = T.Properties.VariableNames{1};
    
    %% Convert the time table to an array
    temp_values = nan(num_samples,1);

    % Loop over segments
    for s = 1:size(T,1)
        seg = T.(Var1){s};

        % Where are we in the temp values
        start_idx = (s-1)*samples_per_time+1;
        end_idx = s*samples_per_time;

        % Fill up values
        temp_values(start_idx:end_idx) = seg;
    end
    
    %% Fill up values
    values(:,is) = temp_values;
    
end


%[T,annotations] = edfread(fname);

%% Get fs
% Get time between each row
%{
times = T.("Record Time");
time_diff = diff(times);
time_diff = seconds(time_diff(1));
samples_per_time = length(T.TriggerEvent{1});
fs = samples_per_time/time_diff;
%}

%% Parse channel names
vnames =cellstr(info.SignalLabels);
chNames = vnames;%vnames(~ismember(vnames,{'Trigger Event','Patient Event'}));

%% Convert ch data into an array
% Initialize array
nsamples = size(T,1)*samples_per_time;
nchs = length(chNames);

times = linspace(0,num_samples/fs,nsamples);

%% Convert annotations to structure
% Convert times to seconds (start and stop are the same)
% add type and description (make the same)
% make a structure array
n_annotations = size(annotations,1);
if n_annotations == 0
    ann_struct = [];
else
    for ia = 1:n_annotations
        ann_time = seconds(annotations.Onset(ia));
        ann_text = annotations.Annotations(ia);
        ann_struct(ia).start = ann_time;
        ann_struct(ia).stop = ann_time;
        ann_struct(ia).type = ann_text;
        ann_struct(ia).description = ann_text;

    end
end

%% Prep out
out.times = times;
out.values = values;
out.chLabels = chNames;
out.fs = fs;
out.annotations = ann_struct;

%% Example plot
if ~isempty(which_elec)
    if ischar(which_elec)
        label = which_elec;
        which_elec = find(ismember(chNames,which_elec));
        
    else
        label = chNames{which_elec};
    end
    figure
    set(gcf,'position',[300 400 900 300])
    plot(times,values(:,which_elec))
    xlabel('Seconds')
    ylabel('voltage')
    title(sprintf('%s',label))
end

end