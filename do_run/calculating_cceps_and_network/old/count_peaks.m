function n_peaks = count_peaks(signal)


% build new baseline (line connecting first and last point)
baseline = linspace(signal(1),signal(end),length(signal));

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

n_peaks = sum(Ydiff ~= 0);

if 1
    figure
    
    plot(signal)
    hold on
    plot(baseline,'--')
    title(sprintf('%d crossings',n_peaks))
    pause
    close(gcf)
end


end