function show_network(A,ch_info)

%% Change nans to minimum
min_A = min(min(A));
A(isnan(A)) = min_A-0.001;

mean_positions_stim = ch_info.stim_pos;
mean_positions_response = ch_info.response_pos;
stim_labels = ch_info.stim_labels;
response_labels = ch_info.response_labels;
normalize = ch_info.normalize;

im = imagesc(A);
cmap = colormap(parula);
cmap = [0.8 0.8 0.8;cmap];
colormap(cmap);
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
%}

%{
xticklabels([])
yticklabels([])

for k = 1:length(stim_labels)
    text(mean_positions_stim(k),1,...
        stim_labels{k},'HorizontalAlignment','center',...
        'fontsize',20)
end
%{
for k = 1:length(response_labels)
    text(mean_positions_stim(k),mean_positions_response(1)-...
        0.05*(mean_positions_response(end)-mean_positions_response(1)),...
        response_labels{k},'HorizontalAlignment','center')
end
%}
%}

%xticks
xlabel('Stim electrode','fontsize',20)
ylabel('Response electrode','fontsize',20)
%set(im,'AlphaData',~isnan(A))
set(gca,'fontsize',20)



end