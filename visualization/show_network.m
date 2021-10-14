function show_network(out)

which = 1;
do_log = 1;
do_save = 1;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;


stim_chs = out.stim_chs;
response_chs = out.response_chs;
A = out.network(which).A;

A(~response_chs,:) = [];
A(:,~stim_chs) = [];
if do_log
    A = log(A);
end

figure
set(gcf,'position',[440   278   689   519])
imagesc(A);
hold on
xticklabels([])
yticklabels([])
xlabel('Stimulation site')
ylabel('Response site')
set(gca,'fontsize',20)

if do_save
    print([results_folder,'plots/pretty_net'],'-dpng')
end


end