function all_fc_ccep_corr

%% Parameters
do_fisher =1;
do_all_plots = 0;
do_symmetric = 1;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

%% Look through out files for pc structures
out_file_folder = [results_folder,'out_files/'];
listing = dir([out_file_folder,'pc*']);

all_rin = [];
all_rout = [];
all_nin = [];
all_nout = [];
names = {};

for i = 1:length(listing)
    
    pc_fname = listing(i).name;
    C = strsplit(pc_fname,'_');
    
    % Make sure results ccep file also exists
    cceps_fname = ['results_',C{2},'_',C{3}];
    if exist([out_file_folder,cceps_fname],'file') == 0
        continue
    end
    
    pt_name = C{2};
    
    % Load both files
    ccep_out = load([out_file_folder,cceps_fname]);
    ccep_out = ccep_out.out;
    
    pc_out = load([out_file_folder,pc_fname]);
    pc_out = pc_out.pout;
    
    % Get stats for PC-CCEP correlations
    stats = new_fc_ccep_corr(ccep_out,pc_out,do_all_plots,do_symmetric);
    
    rin = stats.in.r;
    rout = stats.out.r;
    nin = stats.in.n;
    nout = stats.out.n;
    
    all_rin = [all_rin;rin];
    all_rout = [all_rout;rout];
    all_nin = [all_nin;nin];
    all_nout = [all_nout;nout];
    names = [names;pt_name];
    
end

npts = length(names);

%% Fisher transform
all_zin = ccep_fisher_transform(all_rin,all_nin);
all_zout = ccep_fisher_transform(all_rout,all_nout);

%% Do a two-sided unpaired t-test on r values
if do_fisher
    [~,pin] = ttest(all_zin);
    [~,pout] = ttest(all_zout);
else
    [~,pin] = ttest(all_rin);
    [~,pout] = ttest(all_rout);
end

figure
set(gcf,'position',[344 369 1019 292])
main_axis = tiledlayout(1,2,'TileSpacing','compact','padding','compact');

%% Outdegree
nexttile
plot(all_rout,'o','markersize',15,'linewidth',2)
xlim([0.5 npts+0.5])
hold on
plot(xlim,[0 0],'k--','linewidth',2)
xticks(1:npts)
xticklabels(names)
ylim([-1 1])
xl = xlim;
yl = ylim;
text(xl(2),yl(2),sprintf('p = %1.2f',pout),'fontsize',20,...
    'HorizontalAlignment','right','VerticalAlignment','Top')
ylabel('Outdegree-PC correlation')
set(gca,'fontsize',20)

%% Indegree
nexttile
plot(all_rin,'o','markersize',15,'linewidth',2)
xlim([0.5 npts+0.5])
hold on
plot(xlim,[0 0],'k--','linewidth',2)
xticks(1:npts)
xticklabels(names)
ylim([-1 1])
text(xl(2),yl(2),sprintf('p = %1.2f',pin),'fontsize',20,...
    'HorizontalAlignment','right','VerticalAlignment','Top')
ylabel('Indegree-PC correlation')
set(gca,'fontsize',20)

%% Save
out_dir = [results_folder,'fc_corr/'];
if ~exist(out_dir,'dir')
    mkdir(out_dir);
end
print(gcf,[out_dir,'combined'],'-dpng');

end