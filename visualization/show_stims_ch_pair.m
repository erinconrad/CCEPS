function show_stims_ch_pair(out,sch,rch)

%% Parameters
do_bipolar = 1;

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
fs = out.stim.fs;
start_time = out.clinical.start_time;

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
    
    if max(abs(vals)) > 1e3
        vals = nan(size(vals));
    end
    
    all_traces(:,t) = vals;
end

alt_avg = nanmean(all_traces,2);
if 0
    plot(alt_avg);
end

tw = surround_times;
pt = linspace(tw(1),tw(2),size(alt_avg,1));
st = 1;

f=figure;
set(f,'position',[187 439 1250 359])


subplot(1,2,2)
plot(pt,alt_avg,'linewidth',2)
set(gca,'fontsize',20)
xlabel('Time (s)')
ylabel('\muV')
xlim([tw(1) tw(2)])

ax = subplot(1,2,1);

for t = 1:nt
    all_pt = linspace(tw(1),tw(2),bits(t,end)-bits(t,1)+1);
    if do_bipolar
        vals = bipolar_montage(values(bits(t,1):bits(t,end),:),rch,chLabels);
    else
        vals = values(bits(t,1):bits(t,end),rch);
    end
    vals = vals - mean(vals);
    plot(all_pt,vals,'color',[0.5 0.5 0.5])    
    hold on
end
set(gca,'fontsize',20)
xlabel('Time (s)')
ylabel('\muV')
xlim([tw(1) tw(2)])
all_pt = linspace(tw(1),tw(2),bits(st,end)-bits(st,1)+1);
if do_bipolar
    vals = bipolar_montage(values(bits(st,1):bits(st,end),:),rch,chLabels);
else
    vals = values(bits(st,1):bits(st,end),rch);
end
vals = vals - mean(vals);
hst = plot(all_pt,vals,'color','k','linewidth',2);
htext= text(all_pt(end),median(vals),sprintf('Trial %d',st),'fontsize',20);
gdata.hst = hst;
gdata.ax = ax;
gdata.htext = htext;
gdata.values = values;
gdata.st = st;
gdata.bits = bits;
gdata.rch = rch;
gdata.tw = tw;
gdata.do_bipolar = do_bipolar;
gdata.chLabels = chLabels;
guidata(f,gdata);
set(f,'keypressfcn',@(h,evt) arrow_through(h,evt));
    %n = input('\nEnter trial number you wish to highlight\n');
    %st = n;
    
    
    %delete(hst)
    %delete(htext)
end




function arrow_through(H,E)


str = E.Key;

gdata = guidata(H);
hst = gdata.hst;
htext = gdata.htext;
values = gdata.values;
st = gdata.st;
bits = gdata.bits;
rch = gdata.rch;
tw = gdata.tw;
ax = gdata.ax;
chLabels = gdata.chLabels;
do_bipolar = gdata.do_bipolar;

if strcmp(str,'downarrow')
    st = max(1,st-1);
elseif strcmp(str,'uparrow')
    st = min(size(bits,1),st+1);
else
    return
end


% delete old
delete(hst)
delete(htext)

% plot new
axes(ax);
all_pt = linspace(tw(1),tw(2),bits(st,end)-bits(st,1)+1);
if do_bipolar
    vals = bipolar_montage(values(bits(st,1):bits(st,end),:),rch,chLabels);
else
    vals = values(bits(st,1):bits(st,end),rch);
end
vals = vals - mean(vals);
hst = plot(all_pt,vals,'color','k','linewidth',2);
htext= text(all_pt(end),median(vals),sprintf('Trial %d',st),'fontsize',20);
gdata.hst = hst;
gdata.htext = htext;
gdata.st = st;
guidata(H,gdata);

end