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
    % take the absolute value of the signal
    C = abs(eeg);
    
    
    case 'cov'
    % Take the cross covariance between the EEG and the pulse function
    C = xcov(eeg,pulse,maxlag);
    
end



%% Find the points that cross above the threshold
thresh_C = median(C) + n_stds*std(C);
above_thresh = C > thresh_C;
amps = C(above_thresh)-median(C);
unsigned = eeg(above_thresh)-median(eeg);

% Get index
peak_idx = round(lags((above_thresh)) + nsamples/2);


peak_idx_out = peak_idx';
amps_out = amps;
out = [peak_idx_out,amps_out,unsigned];
%}
%% Remove redundant peaks
%{
[peak_idx,I] = sort(peak_idx);
amps = amps(I);



% Divide the record into bins of too_close size
nbins = floor(length(eeg)/too_close);
bins = linspace(1,length(eeg)-too_close,nbins);

peak_idx_out = [];
amps_out = [];

% loop through bins
for i = 1:length(bins)
    
    % find peaks in the current bin
    curr_peaks = find(peak_idx>=bins(i) & peak_idx < bins(i) + too_close);
    curr_amps = amps(curr_peaks);
    curr_idx = peak_idx(curr_peaks);
    
    % find the max
    [max_amp,I] = max(curr_amps);
    peak_idx_out = [peak_idx_out;curr_idx(I)];
    amps_out = [amps_out;max_amp];
end

out = [peak_idx_out,amps_out];
%}

%{
% Loop through all
for i = 1:length(keep)-1
    
    % Take current amplitude and idx
    highest = amps(i);
    
    % Loop through subsequent ones after this
    for j = i+1:i+1%length(keep)
        
       % see if they are within close of each other
       if peak_idx(j) - peak_idx(i) < too_close
           
           % see which one is higher
            if amps(j) > highest
                % if new one higher, make this the new index one
                highest = amps(j);
                keep(i) = 0; % set old index to not be kept
            else
                keep(j) = 0; % set new index to not be kept
            end
       end
    end
end
orig_peak_idx = peak_idx;
peak_idx(keep == 0) = [];
amps(keep == 0) = [];
out = [peak_idx',amps];
%}


%{
% Loop through the times it changes sign and find the highest amplitude
% point in between
change_sign_idx = find(diff(above_thresh));
for c = 1:2:length(change_sign_idx)-1
    above = change_sign_idx(c):change_sign_idx(c+1);
    
    % Confirm that the middle one is above thresh
    med = round(median(change_sign_idx(c):change_sign_idx(c+1)));
    amp = C(med);
    
    if ~(amp>thresh_C), error('what'); end
      
    % Get index
    idx = round(lags((med)) + nsamples/2);
    
    % Add this to the peaks
    peak_idx = [peak_idx;idx];
    amps = [amps;amp];
end
%}



%{
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
%}

if 0
    figure;
    subplot(2,1,1)
    plot(times,eeg)
    hold on
    %plot(times(peak_idx),eeg(peak_idx),'o')
    plot(times(peak_idx_out),eeg(peak_idx_out),'o')


    subplot(2,1,2)
    plot(C)
    hold on
    plot(get(gca,'xlim'),[thresh_C thresh_C])
    %plot(big_peaks,amps,'o')
    pause
    close(gcf);
end

end