function show_network(A,ch_info)

%% Change nans to minimum
min_A = min(min(A));
A(isnan(A)) = min_A-0.001;

mean_positions_stim = ch_info.stim_pos;
mean_positions_response = ch_info.response_pos;
stim_labels = ch_info.stim_labels;
response_labels = ch_info.response_labels;
stim_edges = ch_info.stim_edges;
response_edges = ch_info.response_edges;
normalize = ch_info.normalize;

im = imagesc(A);
hold on
for i = 1:length(stim_edges)
    plot([stim_edges(i) stim_edges(i)],get(gca,'ylim'),'k');
end
for i = 1:length(response_edges)
    plot(get(gca,'xlim'),[response_edges(i) response_edges(i)],'k');
end
cmap = colormap(parula);
cmap = [0.85 0.85 0.85;cmap];
colormap(cmap);
c = colorbar('location','northoutside','fontsize',30);
c.Label.String = sprintf('Normalized %s (z-score)',ch_info.waveform);
%{
xticks(1:length(stim_chs))
yticks(1:length(response_chs))
xticklabels(chLabels(stim_chs))
yticklabels(chLabels(response_chs))
%}

xticks(mean_positions_stim)
yticks(mean_positions_response)

response_labels = justify_labels(response_labels,'right');
stim_labels = justify_labels(stim_labels,'center');
yticklabels(response_labels)
xticklabels(stim_labels)
%xticklabels(cellfun(@char,stim_labels,'UniformOutput',false))
%yticklabels(cellfun(@char,response_labels,'UniformOutput',false))
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
xlabel('Stimulation electrode','fontsize',25)
ylabel('Response electrode','fontsize',25)
%set(im,'AlphaData',~isnan(A))
set(gca,'fontsize',25)
set(gca,'fontname','Monospac821 BT');


end