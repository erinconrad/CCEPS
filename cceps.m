function cceps


%{

fix timing in get waveforms

play around with waveform detector

Remove bad electrodes

clever way to display anatomic connections

%}

%% Parameters
% ieeg parameters
dataName = 'HUP212_CCEP';
pwfile = '/Users/erinconrad/Desktop/research/gen_tools/eri_ieeglogin.bin';
times = [18893 21999];%[12946 13592]; % if empty, returns full duration

% Stimulation parameters
stim.pulse_width = 300e-6;
stim.train_duration = 30;
stim.stim_freq = 1;
stim.current = 3;
stim.fs = 512;

% Plotting prep
mydir  = pwd;
idcs   = strfind(mydir,'/');
newdir = mydir(1:idcs(end)-1);

%% Get EEG data
%values = make_fake_eeg(stim);

data = download_eeg(dataName,pwfile,times);
values = data.values;
if stim.fs ~= data.fs
   fprintf('\nWarning, fs is different, changing\n'); 
   stim.fs = data.fs;
end
fprintf('\nGot data\n');

%% Get anatomic locations
ana = anatomic_location(dataName,data.chLabels);

%% plot example time
%plot_example_time(values,ex_time,times(1),stim,data.chLabels,1:length(data.chLabels))

%% Do pre-processing??

%% Identify stimulation artifacts
% Loop over EEG
nchs = size(values,2);
artifacts = cell(nchs,1);
for ich = 1:nchs
    artifacts{ich} = find_stim_artifacts(stim,values(:,ich));
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
%final_artifacts = identify_stim_chs(artifacts,stim);

%elecs = alt_find_stim_chs(artifacts,stim,data.chLabels);
 elecs = define_ch(artifacts,stim,data.chLabels);



%% Say which electrodes have stim
stim_chs = true_stim(dataName);
[extra,missing] = find_missing_chs(elecs,stim_chs,data.chLabels);
fprintf('\nMistakenly found stim on:\n')
for i = 1:length(extra)
    fprintf('%s\n',data.chLabels{extra(i)});
end

fprintf('\nMissed stim on:\n')
for i = 1:length(missing)
    fprintf('%s\n',data.chLabels{missing(i)});
end

%% Perform signal averaging
elecs = signal_average(values,elecs,stim);


%% Plot a long view of the stim and the relevant electrodes
show_stim(elecs,values,data.chLabels,[18 19])

%% Plot the average for an example
%figure; plot(elecs(134).n1(:,1))
show_avg(elecs,stim,data.chLabels,'LH06','LA10')

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim,data.chLabels);

%% Build a network
[A,ch_info] = build_network(elecs,stim,'n1',nchs,data.chLabels,ana,1,1);

%% Pretty plot
%{
figure
set(gcf,'position',[1 11 1400 900])
gap = 0.05;
[ha,pos]=tight_subplot(2,1,[gap 0.01],[0.15 0.02],[.12 .02]);

pos_diff = pos{1}(4)/2;

axes(ha(1))
set(ha(1),'pos',[pos{1}(1) pos{1}(2)+pos_diff pos{1}(3) pos{1}(4)-pos_diff])
show_avg(elecs,stim,data.chLabels,'LF01','LE03')

axes(ha(2))
set(ha(2),'pos',[pos{2}(1) pos{2}(2) pos{2}(3) pos{2}(4)+pos_diff-gap])
show_network(A,ch_info);

print(gcf,[newdir,'/cceps_results/pretty_ex'],'-dpng');
%}

end