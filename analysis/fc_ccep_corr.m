
%% Get stim labels
stim_labels = out.ch_info.stim_labels;
response_labels = out.ch_info.response_labels;

% which response labels are also stim
is_stim = ismember(response_labels,stim_labels);
is_response = ismember(stim_labels,response_labels);
is_both = ismember(chLabels,stim_labels) & ismember(chLabels,response_labels);
restricted_labels = chLabels(is_both);

%% Reduce A to just restricted
A = out.A;
B = A(is_stim,is_response);

%% Get PC labels
pc_labels = pout.keep_labels;
is_pc = ismember(restricted_labels,pc_labels);

%% Build final CCEP network
final_labels = restricted_labels(is_pc);
ccep = B(is_pc,is_pc);

%% Get pc network
pc = pout.pc;
pc_labels = pout.keep_labels;
is_ccep_label = ismember(pc_labels,final_labels);
pc = pc(is_ccep_label,is_ccep_label);

if ~isequal(size(ccep),size(pc))
    error('oh no')
end

if 1
    figure
    tiledlayout(1,2)
    nexttile
    imagesc(ccep)

    nexttile
    imagesc(pc)
end