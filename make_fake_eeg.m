function fake_eeg = make_fake_eeg(stim)

%% Parameters
nseconds = 1000;
nsamples = nseconds * stim.fs;
nchs = 2;

%% Fake EEG signal with pulses
pw = round(stim.pulse_width * stim.fs);

% initialize sample
fake_eeg = zeros(nsamples,nchs);

% Make pulses in ch 1
offset = 500;
amp = 100;
for i = 1:stim.train_duration
    pulse_time_start = i*stim.stim_freq*stim.fs + offset;
    pulse_time_end = pulse_time_start + pw;
    fake_eeg(round(pulse_time_start):round(pulse_time_end),1) = amp;
end

last_pulse_end = stim.train_duration*stim.stim_freq*stim.fs + offset + pw;

% Add a misplaced pulse in ch 1
fake_eeg(2700:2700+pw,1) = amp;

% Smaller pulses at same time in 2
for i = 1:stim.train_duration
    pulse_time_start = i*stim.stim_freq*stim.fs + offset;
    pulse_time_end = pulse_time_start + pw;
    fake_eeg(round(pulse_time_start):round(pulse_time_end),2) = amp/2;
end

% Make pulses in ch 2
for i = 1:stim.train_duration
    pulse_time_start = i*stim.stim_freq*stim.fs + last_pulse_end + offset;
    pulse_time_end = pulse_time_start + pw;
    fake_eeg(round(pulse_time_start):round(pulse_time_end),2) = amp;
end

% Add a misplaced pulse in ch 1
fake_eeg(3100 + last_pulse_end:3100+pw + last_pulse_end,2) = amp;

% Add random noise
fake_eeg = fake_eeg + 0.2*randn(nsamples,nchs);

end