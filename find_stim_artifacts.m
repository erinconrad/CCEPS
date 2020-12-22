function out = find_stim_artifacts(stim,eeg)

%% Parameters
n_stds = 8;

%% Generate rectangular pulse function (used to find artifact)
nsamples = size(eeg,1);
pulse = zeros(nsamples,1);
pw = round(stim.pulse_width * stim.fs);
pulse(round(nsamples/2-pw/2):round(nsamples/2+pw/2)) = 1;


%% Take the cross covariance between the EEG and the pulse function
maxlag = round(nsamples/2-pw/2);
C = xcov(eeg,pulse,maxlag);
lags = -maxlag:maxlag;

%% Find the points that cross above the threshold
% Find peaks
[peak,amps] = peaks_ec(C);

% Peaks that cross threshold
thresh_C = median(C) + n_stds*std(C);
big_peaks = peak(amps>thresh_C);
amps = amps(amps>thresh_C);
orig_amps = amps;

% Get index of peaks relative to start of EEG file
peak_idx = round(nsamples/2 + lags(big_peaks));

%% Remove redundant peaks
[peak_idx,I] = sort(peak_idx);
amps = amps(I);

keep = ones(length(peak_idx),1);
% If two peaks within pw*2 of each other, take the higher one
for i = 1:length(keep)-1
   if peak_idx(i+1) - peak(i) < pw
        if amps(i+1) > amps(i)
            
            keep(i) = 0;
        else
            keep(i+1) = 0;
        end
   end
end

peak_idx(keep == 0) = [];
amps(keep == 0) = [];

peak_idx = peak_idx';

out = [peak_idx,amps];

if 0
    figure
    subplot(2,1,1)
    plot(eeg)
    hold on
    plot(peak_idx,eeg(peak_idx),'o')
    
    subplot(2,1,2)
    plot(C)
    hold on
    plot(get(gca,'xlim'),[thresh_C thresh_C])
    plot(big_peaks,amps,'o')
    pause
    close(gcf)
end

end