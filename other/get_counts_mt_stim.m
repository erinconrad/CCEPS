%% get # mt
npts = length(pt);
is_mt = nan(npts,1);
target_list = {'LA1','LA2','LA3','LB1','LB2','LB3','LC1','LC2','LC3',...
    'RA1','RA2','RA3','RB1','RB2','RB3','RC1','RC2','RC3'};

for i = 1:npts
    curr_stim_chs = pt(i).stim_chs;
    is_mt(i) = any(ismember(curr_stim_chs,target_list));


end

fprintf('\n%d of %d patients (%1.1f%%) had MT stim\n',...
    sum(is_mt ==1),npts,sum(is_mt ==1)/npts*100);