function show_stims_ch_pair(out,sch,rch)
% 77, 82

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
tw = surround_times;
pt = linspace(tw(1),tw(2),size(avg,1));
st = 1;

f=figure;
set(f,'position',[187 439 1250 359])


subplot(1,2,2)
plot(pt,avg,'linewidth',2)
set(gca,'fontsize',20)
xlabel('Time (s)')
ylabel('\muV')
xlim([tw(1) tw(2)])

ax = subplot(1,2,1);

for t = 1:nt
    all_pt = linspace(tw(1),tw(2),bits(t,end)-bits(t,1)+1);
    vals = values(bits(t,1):bits(t,end),rch);
    plot(all_pt,vals,'color',[0.5 0.5 0.5])    
    hold on
end
set(gca,'fontsize',20)
xlabel('Time (s)')
ylabel('\muV')
xlim([tw(1) tw(2)])
all_pt = linspace(tw(1),tw(2),bits(st,end)-bits(st,1)+1);
vals = values(bits(st,1):bits(st,end),rch);
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
vals = values(bits(st,1):bits(st,end),rch);
hst = plot(all_pt,vals,'color','k','linewidth',2);
htext= text(all_pt(end),median(vals),sprintf('Trial %d',st),'fontsize',20);
gdata.hst = hst;
gdata.htext = htext;
gdata.st = st;
guidata(H,gdata);
end