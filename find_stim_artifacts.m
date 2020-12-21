function peak_idx = find_stim_artifacts(stim,eeg)

%% Parameters
n_stds = 2;

%% Generate rectangular pulse function (used to find artifact)
nsamples = size(eeg,1);
pulse = zeros(nsamples,1);
pw = stim.pulse_width * stim.fs;
pulse(round(nsamples/2-pw/2):round(nsamples/2+pw/2)) = 1;

%% Fake EEG signal with pulses
fake_eeg = zeros(nsamples,1);
fake_eeg(200:200+pw) = 1;
fake_eeg(600:600+pw) = 1;
fake_eeg = fake_eeg + 0.2*randn(nsamples,1);

%% Take the cross covariance between the EEG and the pulse function
C = xcov(fake_eeg,pulse);
lags = -nsamples+1:nsamples-1;

%% Find the points that cross above the threshold
% Find peaks
[peak,amps] = peaks_ec(C);

% Peaks that cross threshold
thresh_C = median(C) + n_stds*std(C);
big_peaks = peak(amps>thresh_C);

% Get index of peaks relative to start of EEG file
peak_idx = round(nsamples/2 + lags(big_peaks));

end