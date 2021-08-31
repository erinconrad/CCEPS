function show_all_global_measures

%% Parameters
wav = 'n1';
measures = {'D','T','Q','E'};

%% File locs
locations = cceps_files; % Need to make a file pointing to you own path
script_folder = locations.script_folder;
results_folder = locations.results_folder;
addpath(genpath(script_folder));
cceps_folder = [results_folder,'out_files/'];
out_folder = [results_folder,'analysis/global/'];

if ~exist(out_folder,'dir'), mkdir(out_folder); end


% Loop through mat files in out_files directory
listing = dir([cceps_folder,'*.mat']);
npts = length(listing);

%% Initialize matrices
all_measures = nan(length(measures),npts);
meas_names = cell(length(measures),1);
pt_names = cell(npts,1);

%% Get the stuff
for l = 1:npts
    path = [cceps_folder,listing(l).name];
    
    % Load the cceps file
    out = load(path);
    out = out.out;
    
    name = out.name;
    name = strrep(name,'_','');
    name = strrep(name,'CCEP','');
    pt_names{l} = name;
    
    % Get the global measures
    gl = obtain_global_network_measures(out);
    
    wav_name = gl.(wav).waveform;
    
    % loop over measures
    for m = 1:length(measures)
        meas = measures{m};
        
        % Fill up the matrix of measures
        all_measures(m,l) = gl.(wav).measures.(meas).data;
        meas_names{m} = gl.(wav).measures.(meas).name;
    end
    
end

%% Make a plot
figure
set(gcf,'position',[440 59 889 738])
tiledlayout(length(measures),1,'tilespacing','tight','padding','tight')

for m = 1:length(measures)
    nexttile
    plot(all_measures(m,:),'o','markersize',10,'linewidth',2)
    xticks(1:npts)
    xticklabels(pt_names) 
    title(meas_names{m})
end

% Save the plot
print(gcf,[out_folder,wav],'-dpng');

end