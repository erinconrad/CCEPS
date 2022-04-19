function out = new_build_network(out,do_gui)

if ~exist('do_gui','var'), do_gui = 0; end

%% Parameters
thresh_amp = 4;
wavs = {'N1','N2'};

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

%% Basic info
elecs = out.elecs;
chLabels = out.chLabels;
nchs = length(chLabels);
keep_chs = get_chs_to_ignore(chLabels);

% Loop over n1 and n2
for w = 1:length(wavs)

    which = wavs{w};
    A = nan(nchs,nchs);

    %% initialize rejection details
    details.thresh = thresh_amp;
    details.which = which;
    details.reject.sig_avg = nan(length(elecs),length(elecs));
    details.reject.pre_thresh = nan(length(elecs),length(elecs));
    details.reject.at_thresh = nan(length(elecs),length(elecs));
    details.reject.keep = nan(length(elecs),length(elecs));

    for ich = 1:length(elecs)

        if isempty(elecs(ich).arts), continue; end

        arr = elecs(ich).(which);

        % Add peak amplitudes to the array
        A(ich,:) = arr(:,1);


        all_bad = logical(elecs(ich).all_bad);
        details.reject.sig_avg(ich,:) = all_bad;
        details.reject.pre_thresh(ich,:) = isnan(elecs(ich).(which)(:,1)) & ~all_bad;
        details.reject.at_thresh(ich,:) = elecs(ich).(which)(:,1) < thresh_amp;
        details.reject.keep(ich,:) = elecs(ich).(which)(:,1) >= thresh_amp;
        %{
        all_nans = (sum(~isnan(elecs(ich).avg),1) == 0)';
        details.reject.sig_avg(ich,:) = all_nans;
        details.reject.pre_thresh(ich,:) = isnan(elecs(ich).(which)(:,1)) & ~all_nans;
        details.reject.at_thresh(ich,:) = elecs(ich).(which)(:,1) < thresh_amp;
        details.reject.keep(ich,:) = elecs(ich).(which)(:,1) >= thresh_amp;
        %}
    end

    % Add details to array
    out.rejection_details(w) = details;


    %% Remove ignore chs
    stim_chs = nansum(A,2) > 0;
    response_chs = keep_chs;
    A(:,~response_chs) = nan;
    A = A';
    A0 = A;

    %% Normalize
    A(A0<thresh_amp) = 0;
    
    %% Add this to array
    if w == 1
        out.stim_chs = stim_chs;
        out.response_chs = response_chs;
    end
    
    out.network(w).which = which;
    out.network(w).A = A;

end

%% Convert electrode labels to anatomic locations
%{
response_labels = chLabels(response_chs);
stim_labels = chLabels(stim_chs);
mean_positions_response = 1:length(response_labels);
mean_positions_stim = 1:length(stim_labels);
edge_positions_response = [];
edge_positions_stim = []; 
    

ch_info.response_chs = response_chs;
ch_info.stim_chs = stim_chs;
ch_info.stim_pos = mean_positions_stim;
ch_info.response_pos = mean_positions_response;
ch_info.stim_labels = stim_labels;
ch_info.response_labels = response_labels;
ch_info.normalize = normalize;
ch_info.response_edges = edge_positions_response;
ch_info.stim_edges = edge_positions_stim;
ch_info.waveform = which;
%}


%{
in_degree = nansum(A,2);
[in_degree,I] = sort(in_degree,'descend');
in_degree_chs = chs(I);

out_degree = nansum(A,1);
[out_degree,I] = sort(out_degree,'descend');
out_degree_chs = chs(I);

if isempty(ana)
    all_labels = chLabels;
else
    all_labels = ana(chs);
end
ana_word = justify_labels(all_labels,'none');

if normalize == 1 || normalize == 0
fprintf('\nThe highest in-degree channels (note normalization!) are:\n');
for i = 1:min(10,length(in_degree))
    fprintf('%s (%s) (in-degree = %1.1f)\n',...
        chLabels{in_degree_chs(i)},ana_word{in_degree_chs(i)},in_degree(i));
end
end

if normalize == 2 || normalize == 0
fprintf('\nThe highest out-degree channels (note normalization!) are:\n');
for i = 1:min(10,length(out_degree))
    fprintf('%s (%s) (out-degree = %1.1f)\n',...
        chLabels{out_degree_chs(i)},ana_word{out_degree_chs(i)},out_degree(i));
end
end
%}

if do_gui == 1
%% PLot
figure
set(gcf,'position',[1 11 1400 900])
show_network_no_fig(out,1,1,0)
stim_ch_idx = find(stim_chs);
response_ch_idx = find(response_chs);

while 1
    try
        [x,y] = ginput;
    catch
        break
    end
    if length(x) > 1, x = x(end); end
    if length(y) > 1, y = y(end); end
    figure
    set(gcf,'position',[215 385 1226 413])
    %tight_subplot(1,1,[0.01 0.01],[0.15 0.10],[.02 .02]);
    show_avg(out,stim_ch_idx(round(x)),response_ch_idx(round(y)),0,1)
    
    pause
    close(gcf)
end
end
%}

end