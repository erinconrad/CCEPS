%% Example N1, N2, waveform plotting
% this assumes you've loaded in a resulting .mat file from the pipeline and
% you have the structure "out" in your Workspace


% Test hypothesis that early spread channels are the same channels that
% have a large N1 response after stimming soz. Suppose soz channel is
% channel 114

% get stim info for channel 114
info = out.elecs(114);

% see the N1 amplitudes and latencies for all other electrodes when
% stimming 114
N1 = info.N1;

% Plot the trial-averaged waveform when stimming ch 114 and recording from
% channel 94
plot(linspace(info.times(1),info.times(2),length(out.elecs(114).avg(:,94))),...
    out.elecs(114).avg(:,94))

% Things to check
%{
- is amplitude negatively correlated with latency (are bigger responses
also earlier)? Check both N1 and N2. 
        - loop over patients
            - loop over stim electrodes
                - measure the spearman rank correlation between N1
                amplitude and latency (and N2 amplitude and latency)
                    N1 corr =  corr(N1(:,1),N1(:,2),'rows','pairwise','type','spearman')
            - take average and std over stim electrodes (or median and IQR)
        - plot this median and IQR as a point and error bars, one point for
        each patient (2 plots-1 for N1 and 1 for N2)
    - do a lit review (start with Corey Keller papers) to see if this
    result has been reported
- Play around with BCT
- Try to work with the CHOP code - Rudy's
    - for the AA_Running_RejectOrKeep_RW code, try commenting out all the
    weird exception handling
    - don't run AA_distance_vs_amp_and_lat or AA_modify_analysisdata
    - DO run AA_random_rejections_keeps(out);


%}