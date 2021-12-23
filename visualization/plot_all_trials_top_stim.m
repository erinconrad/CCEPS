function plot_all_trials_top_stim

%% Parameters
top_n = 10;
which = 1; % 1-> N1, 2-> N2

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
addpath(genpath(script_folder))
results_folder = locations.results_folder;
out_struct_folder = [results_folder,'out_files/'];
out_folder = [results_folder,'individual_trials/'];
if ~exist(out_folder,'dir'), mkdir(out_folder); end

%% Loop over out files
listing = dir([out_struct_folder,'*.mat']);
for l = 1:length(listing)
    
    %% Load the out_structure
    out = load([out_struct_folder,listing(l).name]);
    out = out.out;

    %% Get network
    name = out.name;
    A = out.network(which).A;
    stim_idx = repmat(1:size(A,2),size(A,1),1);
    response_idx = repmat((1:size(A,1))',1,size(A,2));

    %% Find the top N CCEPs responses
    A = A(:); % vectorize
    stim_idx = stim_idx(:);
    response_idx = response_idx(:);
    A(isnan(A)) = -inf; % make nans -inf so t
    [~,I] = sort(A,'descend');
    stim_idx = stim_idx(I);
    response_idx = response_idx(I);

    pairs_to_plot = nan(top_n,2);
    for i = 1:top_n
        pairs_to_plot(i,:) = [stim_idx(i) response_idx(i)];
    end

    %% Plot them
    f1=figure;
    set(f1,'position',[187 439 1400 1000])
    t1 = tiledlayout(f1,top_n/2,4,'tilespacing','tight','padding','tight');
    
    f2=figure;
    set(f2,'position',[187 439 1400 1000])
    t2 = tiledlayout(f2,top_n/2,4,'tilespacing','tight','padding','tight');
    for i = 1:top_n
        show_stims_ch_pair_no_gui(out,pairs_to_plot(i,1),pairs_to_plot(i,2),t1,t2);
    end
    print(f1,[out_folder,name,'_waves'],'-dpng')
    print(f2,[out_folder,name,'_N2s'],'-dpng')
    close all
    
end


end