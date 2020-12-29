function cceps


%{
Should add something to remove cases in which the amplitude around the stim
is too high

play around with waveform detector
%}

%% Parameters
% ieeg parameters
dataName = 'HUP211_CCEP';
pwfile = '/Users/erinconrad/Desktop/research/gen_tools/eri_ieeglogin.bin';
times = [12946 13592]; % if empty, returns full duration
ex_time = 13486;

% Stimulation parameters
stim.pulse_width = 300e-6;
stim.train_duration = 30;
stim.stim_freq = 1;
stim.current = 3;
stim.fs = 512;

allowable_nums = [stim.train_duration:-1:stim.train_duration-5];
pw = stim.pulse_width * stim.fs;
goal_diff = stim.stim_freq * stim.fs;
max_off = 3;

%% Get EEG data
%values = make_fake_eeg(stim);

data = download_eeg(dataName,pwfile,times);
values = data.values;
if stim.fs ~= data.fs, error('what'); end
fprintf('\nGot data\n');

%% plot example time
%plot_example_time(values,ex_time,times(1),stim,data.chLabels,1:length(data.chLabels))

%% Do pre-processing??

%% Identify stimulation artifacts
% Loop over EEG
nchs = size(values,2);
artifacts = cell(nchs,1);
for ich = 1:nchs
    eeg = values(:,ich);
    out = find_stim_artifacts(stim,eeg);
    if isempty(out)
        artifacts{ich} = [];
        continue;
    else
        on_beat = find_offbeat(out(:,1),allowable_nums,goal_diff,max_off);
    end
    if ~isempty(on_beat)
        artifacts{ich} = [out(on_beat(:,1),:),on_beat(:,2)];
        
        if 0
        plot_example_time(values,times(1),times(1),stim,data.chLabels,...
            ich,artifacts,times(2)-times(1))
        
        pause
        close(gcf)
        end
    end
    
    
end


%% Narrow down the list of stimulation artifacts to just one channel each
%final_artifacts = identify_stim_chs(artifacts,stim);

elecs = alt_find_stim_chs(artifacts,stim);
%% Identify separate electrode trials
%elecs = identify_diff_trials(final_artifacts,stim);

%% Perform signal averaging
elecs = signal_average(values,elecs,stim);

%% Identify CCEP waveforms
elecs = get_waveforms(elecs,stim);

%% Build a network
A = build_network(elecs,'n1',nchs);


end