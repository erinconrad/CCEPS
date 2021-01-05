function out = find_stim_artifacts(stim,eeg)



%% Parameters
approach = 'abs';
n_stds = 8; %5
%too_close = 10;

%% Generate rectangular pulse function (used to find artifact)
%times = linspace(0,size(eeg,1)/stim.fs,size(eeg,1));
nsamples = size(eeg,1);
pulse = zeros(nsamples,1);
pw = round(stim.pulse_width * stim.fs);
pulse(round(nsamples/2-pw/2):round(nsamples/2+pw/2)) = 1;
maxlag = round(nsamples/2-pw/2);
lags = -maxlag:maxlag;

switch approach
    
    case 'abs'
    % take the absolute value of the signal minus the median
    C = abs(eeg-median(eeg));
    
    
    case 'cov'
    % Take the cross covariance between the EEG and the pulse function
    C = xcov(eeg,pulse,maxlag);
    
end



%% Find the points that cross above the threshold
%thresh_C = median(C) + n_stds*std(C);
thresh_C = n_stds*std(eeg);
above_thresh = C > thresh_C;
amps = C(above_thresh);
%amps = C(above_thresh)-median(C);
unsigned = eeg(above_thresh)-median(eeg);



% Get index
peak_idx = round(lags((above_thresh)) + nsamples/2);


peak_idx_out = peak_idx';
amps_out = amps;
out = [peak_idx_out,amps_out,unsigned];


if 0
    figure;
    subplot(2,1,1)
    plot(eeg)
    hold on
    %plot(times(peak_idx),eeg(peak_idx),'o')
    plot((peak_idx_out),eeg(peak_idx_out),'o')


    subplot(2,1,2)
    plot(C)
    hold on
    plot(get(gca,'xlim'),[thresh_C thresh_C])
    %plot(big_peaks,amps,'o')
    pause
    close(gcf);
end

end