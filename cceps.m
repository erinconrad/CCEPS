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



%% Get EEG data
%values = make_fake_eeg(stim);

data = download_eeg(dataName,pwfile,times);
values = data.values;
if stim.fs ~= data.fs
   fprintf('\nWarning, fs is different, changing\n'); 
   stim.fs = data.fs;
end
fprintf('\nGot data\n');

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

elecs = alt_find_stim_chs(artifacts,stim,data.chLabels);



%% Say which electrodes have stim
n_stim = 0;
for i = 1:length(elecs)
    if ~isempty(elecs(i).arts)
        fprintf('%s (elec %d) has stim.\n',data.chLabels{i},i);
        n_stim = n_stim + 1;
    end
end
fprintf('%d electrodes have stim.\n',n_stim);

%% Perform signal averaging
elecs = signal_average(values,elecs,stim);


%% Plot a long view of the stim and the relevant electrodes
show_stim(elecs,values,data.chLabels,[])

%% Plot the average for an example
figure; plot(elecs(134).n1(:,1))
show_avg(elecs,stim,data.chLabels,7,20)

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim,data.chLabels);

%% Build a network
build_network(elecs,stim,'n1',nchs,data.chLabels,2);


end