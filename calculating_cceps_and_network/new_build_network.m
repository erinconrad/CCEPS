function [A,ch_info]= new_build_network(out,do_plot)

%{ 
[A,ch_info]= build_network(elecs,stim,which,nchs,chLabels,...
    ana,normalize,do_plot)
 %}

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

%% unpack
elecs = out.elecs;
stim = out.stim;
which = out.waveform;
if ~isfield(out,'bad')
    bad = [];
else
    bad = out.bad;
end
chLabels = out.chLabels;
ana = out.ana;
normalize = out.how_to_normalize;
nchs = length(chLabels);

thresh_amp = 6;

keep_chs = get_chs_to_ignore(chLabels);

chs = 1:nchs;

A = nan(nchs,nchs);

for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    arr = elecs(ich).(which);
    
    % Add peak amplitudes to the array
    A(ich,:) = arr(:,1);
    
end




%% Remove ignore chs
%{
response_chs = chs;
stim_chs = chs(nansum(A,2)>0);
A = A(stim_chs,keep_chs)';
response_chs = response_chs(keep_chs);
A0 = A;
%}
stim_chs = nansum(A,2) > 0;
response_chs = keep_chs;
A(:,~response_chs) = nan;
A = A';
A0 = A;
ch_info.dimensions = {'response','stim'};

%% Normalize
A(A0<thresh_amp) = nan;
plotA = A(response_chs,stim_chs);

%% Convert electrode labels to anatomic locations
if 1%isempty(ana)
    response_labels = chLabels(response_chs);
    stim_labels = chLabels(stim_chs);
    mean_positions_response = 1:length(response_labels);
    mean_positions_stim = 1:length(stim_labels);
    edge_positions_response = [];
    edge_positions_stim = []; 
    
else
    response_ana = ana(response_chs);
    stim_ana = ana(stim_chs);
    
    response_ana_char = cellfun(@char,response_ana,'UniformOutput',false);
    response_ana_char = cellfun(@(x) reshape(x,1,[]),response_ana_char,'UniformOutput',false);
    [response_labels_idx,ia,ic] = unique(response_ana_char,'stable');
    mean_positions_response = zeros(length(response_labels_idx),1);
    edge_positions_response = zeros(length(response_labels_idx),1);
    for i = 1:length(response_labels_idx)-1
        mean_positions_response(i) = mean(ia(i):ia(i+1))-0.5;
        edge_positions_response(i) = ia(i)-0.5;
    end
    mean_positions_response(end) = mean(ia(end):length(response_ana))-0.5;
    edge_positions_response(end) = [ia(end)-0.5];
    response_labels = response_ana(ia);
    
    stim_ana_char = cellfun(@char,stim_ana,'UniformOutput',false);
    stim_ana_char = cellfun(@(x) reshape(x,1,[]),stim_ana_char,'UniformOutput',false);
    [stim_labels_idx,ia,ic] = unique(stim_ana_char,'stable');
    mean_positions_stim = zeros(length(stim_labels_idx),1);
    edge_positions_stim = zeros(length(stim_labels_idx),1);
    for i = 1:length(stim_labels_idx)-1
        mean_positions_stim(i) = mean(ia(i):ia(i+1))-0.5;
        edge_positions_stim(i) = ia(i)-0.5;
    end
    mean_positions_stim(end) = mean(ia(end):length(stim_ana))-0.5;
    edge_positions_stim(end) = [ia(end)-0.5];
    stim_labels = stim_ana(ia);

    
    %{
    [response_labels,ia,ic] = unique(response_ana,'stable');
    mean_positions_response = zeros(length(response_labels),1);
    for i = 1:length(response_labels)-1
        mean_positions_response(i) = mean(ia(i):ia(i+1));
    end
    mean_positions_response(end) = mean(ia(end):length(response_ana));


    [stim_labels,ia,ic] = unique(stim_ana,'stable');
    mean_positions_stim = zeros(length(stim_labels),1);
    for i = 1:length(stim_labels)-1
        mean_positions_stim(i) = mean(ia(i):ia(i+1));
    end
    mean_positions_stim(end) = mean(ia(end):length(stim_ana));
    %}
end

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

if do_plot == 1
%% PLot
figure
set(gcf,'position',[1 11 1400 900])
show_network(plotA,ch_info);
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
    show_avg(out,stim_ch_idx(round(x)),response_ch_idx(round(y)),0)
    
    pause
    close(gcf)
end
end

end