function out = count_crossings(eeg)

out = 0;

% Pick a few points to define signal end
points = [1 length(eeg);...
    round(0.1*length(eeg)) round(0.9*length(eeg));...
    round(0.25*length(eeg)) round(0.75*length(eeg))];

for ip = 1:length(points)
    signal = eeg(points(ip,1):points(ip,2));

    % build new baseline (line connecting first and last point)
    baseline = linspace(signal(1),signal(end),length(signal))';

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
        plot(baseline,'--')
        title(sprintf('%d crossings',n_crossings))
        pause
        close(gcf)
    end

end

end