function show_network(out,which,do_log,do_save)


%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'pretty_nets/'];
if ~exist(out_folder,'dir'), mkdir(out_folder); end


stim_chs = out.stim_chs;
response_chs = out.response_chs;
A = out.network(which).A;
C = out.name;
C = strsplit(C,'_');
name = C{1};


A(~response_chs,:) = [];
A(:,~stim_chs) = [];

if do_log
    A = log(A);
    ltext = '(log scale)';
else
    ltext = '';
end

if which == 1
    wtext = 'N1';
elseif which == 2
    wtext = 'N2';
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
c = colorbar;
ylabel(c,[wtext,' z-score',ltext]);
title([name,' ',wtext])

if do_save
    print([out_folder,name,wtext],'-dpng')
    close(gcf)
end


end