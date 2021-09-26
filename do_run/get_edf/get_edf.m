function out = get_edf(fname,which_elec)

%% Load data as timetable (what)
T = edfread(fname);

%% Get fs
% Get time between each row
times = T.("Record Time");
time_diff = diff(times);
time_diff = seconds(time_diff(1));
samples_per_time = length(T.TriggerEvent{1});
fs = samples_per_time/time_diff;

%% Parse channel names
vnames = T.Properties.VariableNames;
chNames = vnames(~ismember(vnames,{'TriggerEvent','PatientEvent'}))';

%% Convert ch data into an array
% Initialize array
nsamples = size(T,1)*samples_per_time;
nchs = length(chNames);
values = nan(nsamples,nchs);

for c = 1:nchs
    chname = chNames{c};
    ch_data = T.(chname);
    
    % Loop over segments
    for s = 1:length(ch_data)
        seg = ch_data{s};
        
        % Where are we in the values
        start_idx = (s-1)*samples_per_time+1;
        end_idx = s*samples_per_time;
        
        % Fill up values
        values(start_idx:end_idx,c) = seg;
    end
end

times = linspace(0,nsamples/fs,nsamples);

%% Prep out
out.times = times;
out.values = values;
out.chLabels = chNames;
out.fs = fs;

%% Example plot
if ~isempty(which_elec)
    if ischar(which_elec)
        label = which_elec;
        which_elec = find(ismember(chNames,which_elec));
        
    else
        label = chNames(which_elec);
    end
    figure
    set(gcf,'position',[300 400 900 300])
    plot(times,values(:,which_elec))
    xlabel('Seconds')
    ylabel('voltage')
    title(sprintf('%s',label))
end

end