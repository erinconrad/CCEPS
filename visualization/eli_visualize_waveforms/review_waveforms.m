function review_waveforms(subj)


%% load subject's results
if isempty(subj)
    subj = 'HUP218';
end
locations = cceps_files;
load([[locations.results_folder,'out_files/results_'],subj,'_CCEP.mat']);
savedir = fullfile(locations.results_folder,'waveform_review',subj);
mkdir(savedir);

%% review CCEPs waveforms for significant N1s
stim_electrodes = find(~isempty_c({out.elecs.arts}'));
n1_stim = {out.elecs(stim_electrodes).N1}; % select N1 table for each stimulation electrode
thresh_amp = 6; % per Erin's new_build_network.m function
% for each stimulation electrode, get indices of significant N1s (e.g. not
% Nan and amplitude > some threshold)
n1_keep = cellfun(@(x) find(~isnan(x(:,1)) & x(:,1) > thresh_amp),n1_stim,'UniformOutput',false);
% get indices of N1s that met the "get_waveforms" criteria but thrown out
% for z < 6
n1_threshout = cellfun(@(x) find(~isnan(x(:,1)) & x(:,1) <= thresh_amp),n1_stim,'UniformOutput',false);

% find those that were rejected as artifact 
n1_nan = cellfun(@(x) find(isnan(x(:,1))),n1_stim,'UniformOutput',false);

% make plots for each category of N1, store in struct
it.Artifact = n1_nan;
it.Retained = n1_keep;
it.Discard = n1_threshout;

width = 4; height = 2; %in cm, for each subplot
n_stim = length(stim_electrodes);
FIGURE_DISPLAY('off');
for cat = fields(it)' % iterate through struct fields, corresponding to the Retained indices and Discard indices
    cat = char(cat);
    for s = 1:n_stim
        
        fprintf('\nDoing stim ch %d of %d, %s\n',s,n_stim,cat);
        
        s_e = stim_electrodes(s); % convert iterable index to index of stimulation electrode in montage
        % X = out.elecs(s_e).avg(:,it.(cat){s}); % get time series of responses for electrodes with significant (or non-sig) responses
        n_rec = length(it.(cat){s}); % get list of recording electrodes with significant N1s (or non-significant in the case of 'Discard');
        
        if n_rec == 0
            continue
        end
        
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
        saveas(f,fullfile(savedir,['Stim',out.chLabels{s_e},'_',cat,'.pdf']));
        close(f);
    end
end
FIGURE_DISPLAY('on');

end
