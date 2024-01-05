
%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

%% Get elec info
elecs = out.elecs;
reject = out.rejection_details(1).reject;
n1 = out.network(1).A;
n2 = out.network(2).A;

%% Find length of eeg signal
eeg_length = nan;
for i = 1:length(elecs)
    if ~isempty(elecs(i).avg)
        eeg_length = length(elecs(i).avg);
        break
    end
end
if isnan(eeg_length), error('what');end

all_eeg = nan(length(elecs),length(elecs),eeg_length);

%% Fill up eeg info
% Loop over elecs
for ich = 1:length(elecs)
    if ~isempty(elecs(ich).avg)
        all_eeg(ich,:,:) = elecs(ich).avg';
    end
end

%% remove bad ones
bad = reject.sig_avg == 1 | reject.pre_thresh == 1;
bad = repmat(bad,[1 1 size(all_eeg,3)]);
eeg = all_eeg;
eeg(bad) = nan;

%% turn to 2 dimensions
eeg = wrap_or_unwrap_adjacency(eeg);

%% Sanity check
if 0
    % plot average signal
    plot(nanmean(eeg,1));
end

%% Do PCA
eeg_norm = (eeg-nanmean(eeg,1))./nanstd(eeg,[],1);
[coeff,score,latent] = pca(eeg,'rows','complete');
%{
Coeff(:,i) is what the ith principle component looks like
Score(:,i) is how much each observation fits the ith score
Latent(i) is how much the ith principle component explains variance in data
%}


if 0
    % Show principle components
    for i = 1:size(coeff,2)
        plot(coeff(:,i))
        pause
    end 
end

%% Re-unwrap to 3 dimensions
score = wrap_or_unwrap_adjacency(score);

%% Plots
if 0
% Show 
figure
tiledlayout(2,2)

nexttile
turn_nans_white_ccep(n1)

nexttile
turn_nans_white_ccep(n2)

nexttile
turn_nans_white_ccep(score(:,:,1)')

nexttile
turn_nans_white_ccep(score(:,:,2)')


% correlation of n1 with score
s1 = score(:,:,3)';
r = corr(n2(:),s1(:),'rows','pairwise','type','spearman');
figure
plot(n1(:),s1(:),'o')
yl = ylim;
xl = xlim;
text(xl(1),yl(2),sprintf('r = %1.1f',r),'verticalalignment','top')

end

%% Save these
out.pca.score = score(:,:,1:5);
out.pca.coeff = coeff(:,1:5);
out.pca.latent = latent;


