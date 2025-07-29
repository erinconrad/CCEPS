%% make_simple_table
out_dir = '../../results/other/';

chop = load([out_dir,'stim_info_chop.mat']);
hup = load([out_dir,'stim_info.mat']);

chop = chop.pt;
hup = hup.pt;

%% initialize table
VarNames = {'Center','Name','Filenames','NChs','NIntracranial','NStim'};
T = table('Size',[0 6],'VariableTypes',...
    {'cell','cell','cell','double','double','double'},'VariableNames',...
    VarNames);

%% Add info
for c = 1:2
    if c == 1
        s = chop;
        center = {'CHOP'};
    else
        s = hup;
        center = {'HUP'};
    end

    for i = 1:length(s)
        T = [T;table(center,{s(i).name},{s(i).filenames},length(s(i).all_chs),...
            s(i).nchs,s(i).nstim,'VariableNames',VarNames)];

    end
end

writetable(T,[out_dir,'summary.csv'])