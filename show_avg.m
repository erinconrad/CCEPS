function show_avg(elecs,stim,chLabels,ich,jch,wav,plot_title)



%{
%% Parameters
idx_before_stim = 20;
n1_time = [10e-3 30e-3];
n2_time = [50e-3 300e-3];

n1_idx = floor(n1_time*stim.fs)+1;
n2_idx = floor(n2_time*stim.fs)+1;
%}

if ischar(ich)
    ich = find(strcmp(ich,chLabels));
end

if ischar(jch)
    jch = find(strcmp(jch,chLabels));
end

stim_idx = elecs(ich).stim_idx;
    
%{
% redefine n1 and n2 relative to beginning of eeg
temp_n1_idx = n1_idx + stim_idx;
temp_n2_idx = n2_idx + stim_idx;
%}

% Get the eeg
eeg = elecs(ich).avg(:,jch);

%{
% Get the baseline
baseline = mean(eeg(1:stim_idx-idx_before_stim));


% Get the eeg in the n1 and n2 time
n1_eeg = eeg(temp_n1_idx(1):temp_n1_idx(2));
n2_eeg = eeg(temp_n2_idx(1):temp_n2_idx(2));

% subtract baseline
n1_eeg_abs = abs(n1_eeg-baseline);
n2_eeg_abs = abs(n2_eeg-baseline);

% Get sd of baseline
baseline_sd = std(eeg(1:stim_idx-idx_before_stim));

% convert n1_eeg_abs to z score
n1_z_score = n1_eeg_abs/baseline_sd;
n2_z_score = n2_eeg_abs/baseline_sd;

% find the identity of the peaks
[n1_peak,n1_peak_idx] = max(n1_z_score);
[n2_peak,n2_peak_idx] = max(n2_z_score);
%}
arr = elecs(ich).(wav);
idx = stim_idx+arr(jch,2);
time = idx/stim.fs+elecs(ich).times(1);

plot(linspace(elecs(ich).times(1),elecs(ich).times(2),length(eeg)),eeg,'k',...
    'linewidth',2)
hold on
plot(time,eeg(idx),'bX','markersize',20,'linewidth',4);
%{
plot([elecs(ich).times(1) (stim_idx-idx_before_stim)/stim.fs+elecs(ich).times(1)],[baseline baseline])
%}

%{
n1p=plot((n1_peak_idx+ temp_n1_idx(1)-2)/stim.fs+elecs(ich).times(1),...
    eeg(n1_peak_idx+ temp_n1_idx(1)-1),'bX','markersize',30,'linewidth',4);
%}
%{
n2p=plot((n2_peak_idx+ temp_n2_idx(1)-2)/stim.fs+elecs(ich).times(1),...
    eeg(n2_peak_idx+ temp_n2_idx(1)-1),'bX','markersize',15,'linewidth',2);
%}
yticklabels([])
xlabel('Time relative to stimulus (s)')
%{
title(sprintf('Stim: %s, Response: %s',...
    chLabels{ich},chLabels{jch}))
%}
%lp = legend([n1p,n2p],{'N1','N2'},'fontsize',20);
set(gca,'fontsize',30)
set(gca,'fontname','Monospac821 BT')
if plot_title == 1
title(sprintf('Stim: %s, Response: %s, %s at %1.1f ms',...
    chLabels{ich},chLabels{jch},wav,time*1e3))
end
xlim([elecs(ich).times(1) elecs(ich).times(2)])
%}
%{
mydir  = pwd;
idcs   = strfind(mydir,'/');
newdir = mydir(1:idcs(end)-1);
print(gcf,[newdir,'/cceps_results/CCEP_',chLabels{ich},'_',chLabels{jch}],'-dpng');
%}

end