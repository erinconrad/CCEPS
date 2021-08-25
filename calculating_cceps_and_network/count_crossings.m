function out = count_crossings(eeg,baseline)

out = 0;


signal = eeg;


%{
% build new baseline (line connecting first and last point)
baseline = linspace(nanmean(signal(1:round(0.1*length(eeg)))),...
    nanmean(signal(round(0.9*length(eeg)):length(eeg))),length(signal))';
%}

% calculate signal minus baseline
sig_bl = signal-baseline; 
% when sig-bl = 0, signal is at baseline
% when sig-bl <0, < baseline
% when >0, > baseline

% get sign
Y = sign(sig_bl);
% 1 means signal above baseline
% 0 means signal = baseline
% -1 means signal < baseline;

% calculate difference between points
Ydiff = diff(Y);
% non-zero points are crossings (note that I will be double counting in the
% rare occasions in which Y is exactly 0, which only happens when the
% signal is exactly at baseline).

n_crossings = sum(Ydiff ~= 0);

if n_crossings > out
    out = n_crossings;
end

if 0
    figure

    plot(signal)
    hold on
    plot(xlim,[baseline baseline],'--')
    title(sprintf('%d crossings',n_crossings))
    pause
    close(gcf)
end


end