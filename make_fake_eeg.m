function fake_eeg = make_fake_eeg(stim)

%% Parameters
nsamples = 1e5;
nchs = 10;

%% Fake EEG signal with pulses
pw = round(stim.pulse_width * stim.fs);

% initialize sample
fake_eeg = zeros(nsamples,nchs);

% Pulses in channels 1 and 2, bigger in ch 1
fake_eeg(1e4:1e4+pw,1) = 20;
fake_eeg(3e4:3e4+pw,1) = 20;
fake_eeg(1e4:1e4+pw,2) = 10;
fake_eeg(3e4:3e4+pw,2) = 10;

% Another pulse in channels 3 and 4
fake_eeg(4e4:4e4+pw,3) = 20;
fake_eeg(4e4:4e4+pw,4) = 10;
fake_eeg(4e4:4e4+pw,1) = 10;


% Add random noise
fake_eeg = fake_eeg + 0.2*randn(nsamples,nchs);

end