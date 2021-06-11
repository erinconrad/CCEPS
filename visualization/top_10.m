function top_10(out,ich,wav)

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

%% Unpack out struct
elecs = out.elecs;
stim = out.stim;
chLabels = out.chLabels;
wav = out.waveform;
C = strsplit(out.name,'_');
name_first = C{1};


if ischar(ich)
    ich = find(strcmp(ich,chLabels));
end

%% Find top 10 response electrodes (in response to stim on this ch)
out_arr = elecs(ich).(wav); % get N1s (or N2)
out_arr = out_arr(:,1); % just the amplitude
out_arr(isnan(out_arr)) = -inf;
[~,sort_out_arr] = sort(out_arr,'descend'); % descending order
top_10_out = sort_out_arr(1:10); % top 10

%% Find the top 10 stim electrodes (based on the response on this ch)
in_arr = nan(length(elecs),1);
for i = 1:length(elecs)
    curr = elecs(i).(wav);
    if isempty(curr), continue; end
    curr = curr(ich,1);
    in_arr(i) = curr;
end
in_arr(isnan(in_arr)) = -inf;
[~,sort_in_arr] = sort(in_arr,'descend'); % descending order
top_10_in = sort_in_arr(1:10); % top 10

figure
set(gcf,'position',[10 400 1400 350])
tiledlayout(2,10,'TileSpacing','compact','padding','compact');

%% Top row show top 10 response electrodes
for i = 1:10
    nexttile
    
    j = top_10_out(i); 
    % Get signal
    sig = elecs(ich).avg(:,j);
    times = linspace(elecs(ich).times(1),elecs(ich).times(2),length(sig));
    plot(times,sig);
    yticklabels([])
    yl = ylim;
    xl = xlim;
    text(xl(2),yl(2),sprintf('%s',out.chLabels{j}),...
        'Horizontalalignment','right','verticalalignment','top')
    
    if i == 1
        ylabel('Response electrode');
    end
end

%% Bottom row show top 10 stim electrodes
for i = 1:10
    nexttile
    
    j = top_10_in(i); 
    % Get signal
    sig = elecs(j).avg(:,ich);
    times = linspace(elecs(j).times(1),elecs(j).times(2),length(sig));
    plot(times,sig);
    yticklabels([])
    yl = ylim;
    xl = xlim;
    text(xl(2),yl(2),sprintf('%s',out.chLabels{j}),...
        'Horizontalalignment','right','verticalalignment','top')
    if i == 1
        ylabel('Stim electrode');
    end
end