function get_anatomic_labels

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



end