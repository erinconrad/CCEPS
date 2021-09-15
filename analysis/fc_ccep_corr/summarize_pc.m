function summarize_pc

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_file_folder = [results_folder,'out_files/'];
out_folder = [results_folder,'analysis/basic_pc/'];
if ~exist(out_folder,'dir'), mkdir(out_folder); end

% add paths
addpath(genpath(script_folder));

% Get files in the out files folder
listing = dir([out_file_folder,'*.mat']);


all_names = {};
available = [];

for i = 1:length(listing)
    fname = listing(i).name;
    C = strsplit(fname,'_');
    dataName = [C{2},'_',C{3}];
    
    out = load([out_file_folder,fname]);
    out = out.out;
    
    all_names = [all_names;out.name];
    if isempty(out.avg_pc)
        available = [available;0];
    else
        available = [available;1];
        keep_chs = get_chs_to_ignore(out.bipolar_labels);
        pc = out.avg_pc;
        pc = pc(keep_chs,keep_chs);
        labels = out.bipolar_labels(keep_chs);
        figure
        turn_nans_white_ccep(pc);
        yticks(1:length(labels))
        yticklabels(labels)
        xticks(1:length(labels))
        xticklabels(labels)
        print(gcf,[out_folder,out.name],'-dpng');
        close(gcf)
    end
    
    
end

table(all_names,available)

end