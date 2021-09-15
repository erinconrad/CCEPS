function ccep_model_responses

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'analysis/model/'];
if ~exist(out_folder,'dir'), mkdir(out_folder); end

% folder with cceps data
cceps_folder = [results_folder,'out_files/'];

% folder with fc data
fc_folder =  '/Users/erinconrad/Desktop/research/FC_toolbox/results/all_out/summary_files/';

% folder with elec loc data
loc_folder = results_folder;
% load it
elecs = load([loc_folder,'elecs.mat']);
info = elecs.info;

% add paths
addpath(genpath(script_folder));

%% Loop over patients
listing = dir([cceps_folder,'*.mat']);
for l = 4%1:length(listing)
    
    fname = [cceps_folder,listing(l).name];
    cceps = load(fname);
    cceps = cceps.out;
    
    C = cceps.name;
    pt_name = strrep(C,'_','');
    pt_name = strrep(pt_name,'CCEP','');
    
    % Get corresponding locs
    found_locs = 0;
    for j = 1:length(info)
        if strcmp(info(j).name,pt_name)
            found_locs = 1;
            break
        end    
    end
    if found_locs == 0, error('why'); end
    
    % Get locs of corresponding ccep labels
    ccep_labels = cceps.chLabels;
    loc_labels = info(j).elecs(end).elec_names;
    
    % find the indices in loc_labels that correspond to ccep labels
    [lia,locb] = ismember(ccep_labels,loc_labels);
    % sanity check
    if ~isequal(loc_labels(locb(lia~=0)),ccep_labels(lia~=0)), error('why'); end
    
    % Get the corresponding locs
    locs = nan(length(ccep_labels),3);
    locs(lia~=0,:) = info(j).elecs(end).locs(locb(lia~=0),:);
    
    % build 1/dist^2 network
    dnet = make_dist_network(locs);
    
    % get cceps network
    cnet = cceps.A;
    stim_chs = cceps.ch_info.stim_chs;
    
    % binarize the mdoel
    % DO THIS!!!!!!! ALSO REMOVE NON INTRACRNIAL CHANNELS AND I,I ELEMENTS
    % think about what i,j and j,i mean now that it is no longer square
    % need to change A so that it is zero, not nan, if subthreshold.
    cnet(isnan(cnet)) = 0;
    %dnet(isnan(dnet)) = 0;
    
    % reduce non-stim (just reduce columns, keep all response)
    %cnet = cnet(:,stim_chs);
    %dnet = dnet(:,stim_chs);
    cnet(:,~stim_chs) = nan;
    %dnet(:,~stim_chs) = nan;
    
    % Get matrices of stim and response electrode designations
    [stim,response] = get_stim_response_elecs(cnet);
    
    % get ut and lt
    ut = logical(triu(ones(size(cnet))));
    lt = logical(tril(ones(size(cnet))));
    cl = cnet(lt);
    dl = dnet(lt);
    cu = cnet(ut);
    du = dnet(ut);
    su = stim(ut);
    sl = stim(lt);
    ru = response(ut);
    rl = response(lt);
    
    % show these side by side and correlate
    if 1
        r = corr(cl,dl,'rows','pairwise');
        figure
        t=tiledlayout(1,2);
        nexttile
        turn_nans_white(cnet)
        nexttile
        turn_nans_white(dnet)
        title(t,sprintf('r = %1.2f',r))
    end
        
    % Prepare model table
    ut = table(cu,du,su,ru,'VariableNames',{'CCEP','invdist','stim','response'});
    lt = table(cl,dl,sl,rl,'VariableNames',{'CCEP','invdist','stim','response'});
    
    % do a linear mixed effects model
    ulme = fitlme(ut,'CCEP~invdist+(1|stim)+(1|response)');
    llme = fitlme(lt,'CCEP~invdist+(1|stim)+(1|response)');
    
end


end