function A= build_network(elecs,stim,which,nchs,chLabels,ana,normalize)

thresh_amp = 6;

keep_chs = get_chs_to_ignore(chLabels);

% Should I normalize??
chs = 1:nchs;
response_chs = chs;

A = nan(nchs,nchs);

for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    arr = elecs(ich).(which);
    
    % Add peak amplitudes to the array
    A(ich,:) = arr(:,1);
    
end

A(A<thresh_amp) = nan;

%% Remove ignore chs
stim_chs = chs(nansum(A,2)>0);
A = A(stim_chs,keep_chs)';
response_chs = response_chs(keep_chs);

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
channel
%}   
    A = (A-nanmean(A,2))./nanstd(A,0,2);
    
end

%% Convert electrode labels to anatomic locations
response_ana = ana(response_chs);
stim_ana = ana(stim_chs);

[response_labels,ia,ic] = unique(response_ana,'stable');
mean_positions_response = zeros(length(response_labels),1);
for i = 1:length(response_labels)-1
    mean_positions_response(i) = min(ia(i):ia(i+1));
end
mean_positions_response(end) = min(ia(end):length(response_ana));


[stim_labels,ia,ic] = unique(stim_ana,'stable');
mean_positions_stim = zeros(length(stim_labels),1);
for i = 1:length(stim_labels)-1
    mean_positions_stim(i) = min(ia(i):ia(i+1));
end
mean_positions_stim(end) = min(ia(end):length(stim_ana));

%% PLot
if 1
    figure
    set(gcf,'position',[1 11 1400 794])
    tight_subplot(1,1,[0.01 0.01],[0.15 0.02],[.12 .02]);
    im = imagesc(A);
    %{
    xticks(1:length(stim_chs))
    yticks(1:length(response_chs))
    xticklabels(chLabels(stim_chs))
    yticklabels(chLabels(response_chs))
    %}
    
    xticks(mean_positions_stim)
    yticks(mean_positions_response)
    xticklabels(stim_labels)
    yticklabels(response_labels)
    
    xticks
    xlabel('Stim electrode','fontsize',20)
    ylabel('Response electrode','fontsize',20)
    set(im,'AlphaData',~isnan(A))
    set(gca,'fontsize',20)
    mydir  = pwd;
    idcs   = strfind(mydir,'/');
    newdir = mydir(1:idcs(end)-1);
    print(gcf,[newdir,'/cceps_results/CCEP_network'],'-dpng');
end

in_degree = nansum(A,2);
[in_degree,I] = sort(in_degree,'descend');
in_degree_chs = response_chs(I);

out_degree = nansum(A,1);
[out_degree,I] = sort(out_degree,'descend');
out_degree_chs = stim_chs(I);

if normalize == 1 || normalize == 0
fprintf('\nThe highest in-degree channels (note normalization!) are:\n');
for i = 1:10
    fprintf('%s (in-degree = %1.1f)\n',chLabels{in_degree_chs(i)},in_degree(i));
end
end

if normalize == 2 || normalize == 0
fprintf('\nThe highest out-degree channels (note normalization!) are:\n');
for i = 1:10
    fprintf('%s (out-degree = %1.1f)\n',chLabels{out_degree_chs(i)},out_degree(i));
end
end


while 1
    [x,y] = ginput;
    if length(x) > 1, x = x(end); end
    if length(y) > 1, y = y(end); end
    show_avg(elecs,stim,chLabels,stim_chs(round(x)),response_chs(round(y)))
    pause
    close(gcf)
end

end