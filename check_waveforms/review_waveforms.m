function review_waveforms(out,subj,locations)

%% prepare space
%clear all; close all; clc;
%% load subject's results
%subj = 'HUP212';
savedir = fullfile(locations.results_folder,'waveform_review',subj);
mkdir(savedir);
%% review CCEPs waveforms for significant N1s
stim_electrodes = find(~isempty_c({out.elecs.arts}'));

random_frac = 0.7; % randomly don't plot some stim channels just to speed life up
for wave = {'N1','N2'}
    wave = char(wave);
    
    nX_stim = {out.elecs(stim_electrodes).(wave)}; % select N1 or N2 table for each stimulation electrode
    thresh_amp = 6; % per Erin's new_build_network.m function
    % for each stimulation electrode, get indices of significant N1/2s (e.g. not
    % Nan and amplitude > some threshold)
    nX_keep = cellfun(@(x) find(~isnan(x(:,1)) & x(:,1) > thresh_amp),nX_stim,'UniformOutput',false);    
    nX_keep(rand(length(nX_keep),1) < random_frac) = {[]};
    % get indices of N1/2s that met the "get_waveforms" criteria but thrown out
    % for z < 6
    %nX_threshout = cellfun(@(x) find(~isnan(x(:,1)) & x(:,1) <= thresh_amp),nX_stim,'UniformOutput',false);
    % ^ temporarily holding the above
    % instead get indices of N1/2s that did NOT meet the get_waveforms criteria
    % but do exclude bad channels, such as ECG or notably noisy channels as
    % denoted by nans in the EEG data
    all_avg = {out.elecs(stim_electrodes).avg};
    nX_threshout = cellfun(@(x,y) find(isnan(x(:,1)) & nansum(y,1)'~=0),nX_stim,all_avg,'UniformOutput',false);
    nX_threshout(rand(length(nX_threshout),1) < random_frac) = {[]};
    
    % make plots for each category of N1, store in struct
    it.Retained = nX_keep;
    it.Discard = nX_threshout;

    width = 4; height = 2; %in cm, for each subplot
    n_stim = length(stim_electrodes);
    FIGURE_DISPLAY('off');
    for cat = fields(it)' % iterate through struct fields, corresponding to the Retained indices and Discard indices
        cat = char(cat);
        for s = 1:n_stim
            s_e = stim_electrodes(s); % convert iterable index to index of stimulation electrode in montage
            % X = out.elecs(s_e).avg(:,it.(cat){s}); % get time series of responses for electrodes with significant (or non-sig) responses
            n_rec = length(it.(cat){s}); % get list of recording electrodes with significant N1/2s (or non-significant in the case of 'Discard');
            if n_rec > 0 % if there are any recording electrodes with significant waveforms, plot them
                f=figure;
                [sp1,sp2] = subplot_ind2(ceil(sqrt(n_rec))^2); % make plot square
                for r = 1:n_rec
                    subplot(sp1,sp2,r); show_avg_eli(out,s_e,it.(cat){s}(r)); % plot each recording electrode's response in a subplot
                    SET_TICKLABEL_FONTSIZE('xy',6); % make tick labels small
                    % I think that the n1 value in the label and the y-axis uV value don't match up
                    % because of the z-scoring. the text label is a z-score and the
                    % y axis is the actual (demeaned) signal
                end
            f=FIGURE_SIZE_CM(f,sp2*width,sp1*height);
            saveas(f,fullfile(savedir,[wave,'_',cat,'_','Stim',out.chLabels{s_e},'.pdf']));            
            close(f);
            end
        end
    end
    FIGURE_DISPLAY('on');
    % so a lot of "CCEPs" don't have very good looking waveforms
end