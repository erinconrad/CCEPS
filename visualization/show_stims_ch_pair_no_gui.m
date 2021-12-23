function show_stims_ch_pair_no_gui(out,sch,rch,t1,t2)

%% Parameters
do_bipolar = 1;
stim_time = [-5e-3 15e-3];

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

%% Get info about time to download
chLabels = out.chLabels(:,1);
if ischar(sch)
    sch = find(strcmp(chLabels,sch));
end
if ischar(rch)
    rch = find(strcmp(chLabels,rch));
end
name = out.name;
fs = out.other.stim.fs;
if ~isfield(out,'clinical')
    start_time = 1;
elseif isnan(out.clinical.start_time)
    start_time = 1;
else
    start_time = out.clinical.start_time;
end

stim_indices = round(stim_time(1)*fs):round(stim_time(2)*fs);

arts = sort(out.elecs(sch).arts);

first_stim_time = arts(1)/fs;
last_stim_time= arts(end)/fs;
surround_times = out.elecs(sch).times;
download_times = [first_stim_time+surround_times(1)+start_time,last_stim_time+surround_times(2)+start_time];
arts_rel_file = arts/fs + start_time;
rel_arts = round((arts_rel_file-download_times(1))*fs);

%% Download ieeg
data = download_eeg(name,loginname, pwfile,download_times);
values = data.values;
bits = [rel_arts + repmat(surround_times(1)*fs,length(rel_arts),1),...
    rel_arts + repmat(surround_times(2)*fs,length(rel_arts),1)];
bits = round(bits);
bits(1,1) = 1;
bits(end,2) = size(values,1);




avg = squeeze(out.elecs(sch).avg(:,rch));
nt = size(bits,1);

% Get alt avg
all_traces = nan(bits(1,end)-bits(1,1)+1,nt);
cmap = colormap(parula(nt));
all_peaks = nan(nt,1);
all_peak_times = nan(nt,1);

for t = 1:nt
    if do_bipolar
        vals = bipolar_montage(values(bits(t,1):bits(t,end),:),rch,chLabels);
    else
        vals = values(bits(t,1):bits(t,end),rch);
    end
    if length(vals) < size(all_traces,1)
        vals = [vals;repmat(vals(end),size(all_traces,1)-length(vals),1)];
    end

    if length(vals) > size(all_traces,1)
        vals(end-(length(vals)-size(all_traces,1))+1:end) = [];
    end
    vals = vals-mean(vals);
    
    
    
    %
    all_idx = 1:length(vals);
    stim_idx = out.elecs(sch).stim_idx;
    stim_indices = stim_indices + stim_idx - 1;
    non_stim_idx = all_idx;
    non_stim_idx(ismember(non_stim_idx,stim_indices)) = [];
    
    if 0
        plot(vals)
        hold on
        plot([stim_indices(1) stim_indices(1)],ylim)
        plot([stim_indices(end) stim_indices(end)],ylim)
    end
    
    %{
    if max(abs(vals(non_stim_idx))) > 1e3
        vals = nan(size(vals));
    end
    %}
    %
    if max(abs(vals)) > 1e3
        vals = nan(size(vals));
    end
    %}
    
    all_traces(:,t) = vals;
    
    %% Get N2 peaks
    stim_idx = out.elecs(sch).stim_idx;
    peak_range = [50e-3 300e-3];
    idx_before_stim = 30;
    [peak,peak_time] = find_peak(vals,fs,stim_idx,peak_range,idx_before_stim);
    all_peaks(t) = peak;
    all_peak_times(t) = peak_time;
end

alt_avg = nanmean(all_traces,2);
if 0
    plot(alt_avg);
end

tw = surround_times;
pt = linspace(tw(1),tw(2),size(alt_avg,1));
st = 1;


%
nexttile(t1)
plot(pt,alt_avg,'linewidth',2)
set(gca,'fontsize',15)
%xlabel('Time (s)')
%ylabel('\muV')
xticklabels([])
yticklabels([])
xlim([tw(1) tw(2)])
xl = xlim;
yl = ylim;
text(xl(1),yl(2),sprintf('%s->%s',chLabels{sch},chLabels{rch}),...
    'verticalalignment','top','fontsize',15)
%}


nexttile(t1)
for t = 1:nt
    all_pt = linspace(tw(1),tw(2),bits(t,end)-bits(t,1)+1);
    if do_bipolar
        vals = bipolar_montage(values(bits(t,1):bits(t,end),:),rch,chLabels);
    else
        vals = values(bits(t,1):bits(t,end),rch);
    end
    vals = vals - mean(vals);
    plot(all_pt,vals,'color',cmap(t,:))    
    hold on
end
set(gca,'fontsize',15)
%xlabel('Time (s)')
%ylabel('\muV')
xticklabels([])
yticklabels([])
xlim([tw(1) tw(2)])
all_pt = linspace(tw(1),tw(2),bits(st,end)-bits(st,1)+1);
if do_bipolar
    vals = bipolar_montage(values(bits(st,1):bits(st,end),:),rch,chLabels);
else
    vals = values(bits(st,1):bits(st,end),rch);
end
vals = vals - mean(vals);

nexttile(t2)
%T = table(all_peaks,all_peak_times,'VariableNames',{'Amplitude','Time'});
%h = stackedplot(T,'o','linewidth',2);
plot(all_peaks,'o','linewidth',2)
ylabel('N2 amplitude (uV)')
xlabel('Trial')
set(gca,'fontsize',15)
xl = xlim;
yl = ylim;
text(xl(1),yl(1),sprintf('%s->%s',chLabels{sch},chLabels{rch}),...
    'fontsize',15)

nexttile(t2)
%T = table(all_peaks,all_peak_times,'VariableNames',{'Amplitude','Time'});
%h = stackedplot(T,'o','linewidth',2);
plot(all_peak_times,'o','linewidth',2)
ylabel('N2 time')
xlabel('Trial')
set(gca,'fontsize',15)



end