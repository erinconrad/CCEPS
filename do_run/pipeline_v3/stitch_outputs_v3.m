function out_st = stitch_outputs(all_out)

%{
Expectation:
- same number response channels, in same order, between two stims
- no repeated stim channels
%}

%% Check some expectations

% Expectation one: same order of response channels
out1 = all_out{1};
chLabels1 = out1.chLabels;
response1 = out1.response_chs;
for i = 1:length(all_out)
    out_curr = all_out{i};
    assert(isequal(chLabels1,out_curr.chLabels))

    assert(isequal(response1,out_curr.response_chs))
end

% No repeated stim channels, warn if there are
stim_chs1 = out1.stim_chs;
for i = 1:length(all_out)
    out_curr = all_out{i};
    if any(stim_chs1 & out_curr.stim_chs)
        fprintf(['Warning, repeated stim for %s on channels:\n',out_curr.filename]);
        out1.chLabels(stim_chs1 & out_curr.stim_chs)
    end
end

%% Prep reconciled out structure
out_st = all_out{1}; % start by defining it as the first one
out_st.filenames = {out_st.filename};
out_st.filename = 'multiple';

for i = 2:length(all_out)
    
    curr_out = all_out{i};

    % add file name
    out_st.filenames(end+1) = {curr_out.filename};

    % add elecs if not empty
    for j = 1:length(curr_out.elecs)
        if ~isempty(curr_out.elecs(j).arts)
            out_st.elecs(j) = curr_out.elecs(j);
        end
    end

    % add out.other.periods if not empty
    for j = 1:length(curr_out.other.periods)
        if ~isempty(curr_out.other.periods(j).start_time)
            out_st.other.periods(j) = curr_out.other.periods(j);
        end

    end

    % add list of stim chs
    out_st.other.stim_elecs = [out_st.other.stim_elecs;chLabels1(curr_out.stim_chs)];

    % no change to response channels by assertion above

    % add stim chs
    out_st.stim_chs = out_st.stim_chs | curr_out.stim_chs;

    % add rejection details
    for j = 1:2
        out_st.rejection_details(j).reject.sig_avg(curr_out.stim_chs) = ...
            curr_out.rejection_details(j).reject.sig_avg(curr_out.stim_chs);

        out_st.rejection_details(j).reject.pre_thresh(curr_out.stim_chs) = ...
            curr_out.rejection_details(j).reject.pre_thresh(curr_out.stim_chs);

        out_st.rejection_details(j).reject.at_thresh(curr_out.stim_chs) = ...
            curr_out.rejection_details(j).reject.at_thresh(curr_out.stim_chs);

        out_st.rejection_details(j).reject.keep(curr_out.stim_chs) = ...
            curr_out.rejection_details(j).reject.keep(curr_out.stim_chs);
    end

    % add network
    for j = 1:2
        out_st.network(j).A(:,curr_out.stim_chs) = curr_out.network(j).A(:,curr_out.stim_chs);
        out_st.network(j).A0(:,curr_out.stim_chs) = curr_out.network(j).A0(:,curr_out.stim_chs);
    end
    
end


end