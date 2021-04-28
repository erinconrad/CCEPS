function pretty_plot(out,stim_ch,response_ch)

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
results_folder = locations.results_folder;
script_folder = locations.script_folder;
addpath(genpath(script_folder));

gap = 0.08;
bump = 0.12;

stim = out.stim;
elecs = out.elecs;
chLabels = out.chLabels;
A = out.A;
ch_info = out.ch_info;
ana = out.ana;
wav = out.waveform;

if ischar(stim_ch)
    stim_ch_idx = find(strcmp(stim_ch,chLabels));
else
    stim_ch_idx = stim_ch;
end
if ischar(response_ch)
    response_ch_idx = find(strcmp(response_ch,chLabels));
else
    response_ch_idx = response_ch;
end
if ~isempty(ana)
    stim_ana = ana(stim_ch_idx);
    response_ana = ana(response_ch_idx);

    stim_ana_char = justify_labels(stim_ana,'none');
    response_ana_char = justify_labels(response_ana,'none');

    fprintf('\nStim anatomical position: %s\n',stim_ana_char{1});
    fprintf('Response anatomical position: %s\n',response_ana_char{1});
end

figure
set(gcf,'position',[1 11 700 800])
[ha,pos] = tight_subplot(2,1,[gap 0.01],[0.10 0.03],[.17 .01]);


axes(ha(1))
set(ha(1),'position',[pos{1}(1),pos{1}(2)+bump+gap,pos{1}(3),pos{1}(4)-bump-gap])
show_avg(out,stim_ch,response_ch,0);
%{
lp_pos = get(lp,'position');
set(lp,'position',[0.05,pos{1}(2)+bump+gap+0.02,lp_pos(3),lp_pos(4)])
%}


axes(ha(2))
set(ha(2),'position',[pos{2}(1),pos{2}(2),pos{2}(3),pos{2}(4)+bump])
show_network(A,ch_info);

annotation('textbox',[0,pos{1}(2)+pos{1}(4)-0.06,0.1,0.1],'String','A',...
    'linestyle','none','fontsize',35);

annotation('textbox',[0,pos{2}(2)+pos{2}(4)+bump,0.1,0.1],'String','B',...
    'linestyle','none','fontsize',35);


print(gcf,[results_folder,'plots/figure1'],'-dpng');

end