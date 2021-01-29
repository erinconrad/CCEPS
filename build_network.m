function [A,ch_info]= build_network(elecs,stim,which,nchs,chLabels,...
    ana,normalize,do_plot)


thresh_amp = 6;

keep_chs = get_chs_to_ignore(chLabels);

chs = 1:nchs;
response_chs = chs;

A = nan(nchs,nchs);

for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    arr = elecs(ich).(which);
    
    % Add peak amplitudes to the array
    A(ich,:) = arr(:,1);
    
end




%% Remove ignore chs
stim_chs = chs(nansum(A,2)>0);
A = A(stim_chs,keep_chs)';
response_chs = response_chs(keep_chs);
A0 = A;

%% Normalize
if normalize == 0 
% do nothing
elseif normalize == 1
% Normalize by stim ch
%{
So this normalizes the response according to other responses on that stim
channel. This sees how big the response on the channel is compared to other
channels encountering the same stim. This would be good for comparing
in-degree across channels but bad for comparing out-degree.
%}
    A = (A-nanmean(A,1))./nanstd(A,0,1);
elseif normalize == 2
% Normalize by response ch
%{
So this normalizes the response according to other stims for that response
channel. This is good for out-degree.
%}   
    A = (A-nanmean(A,2))./nanstd(A,0,2);
    
end

A(A0<thresh_amp) = nan;

%% Convert electrode labels to anatomic locations
if isempty(ana)
    response_labels = chLabels(response_chs);
    stim_labels = chLabels(stim_chs);
    mean_positions_response = 1:length(response_labels);
    mean_positions_stim = 1:length(stim_labels);
    
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
in_degree_chs = response_chs(I);

out_degree = nansum(A,1);
[out_degree,I] = sort(out_degree,'descend');
out_degree_chs = stim_chs(I);

all_labels = ana(chs);
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
tight_subplot(1,1,[0.01 0.01],[0.10 0.02],[.12 .02]);
show_network(A,ch_info);
mydir  = pwd;
idcs   = strfind(mydir,'/');
newdir = mydir(1:idcs(end)-1);
%print(gcf,[newdir,'/cceps_results/CCEP_network'],'-dpng');

while 1
    [x,y] = ginput;
    if length(x) > 1, x = x(end); end
    if length(y) > 1, y = y(end); end
    figure
    set(gcf,'position',[215 385 1226 413])
    tight_subplot(1,1,[0.01 0.01],[0.15 0.10],[.02 .02]);
    show_avg(elecs,stim,chLabels,stim_chs(round(x)),response_chs(round(y)),1)
    
    pause
    close(gcf)
end
end

end