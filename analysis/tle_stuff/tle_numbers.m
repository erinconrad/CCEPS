%% locations

locations = cceps_files;
data_folder = locations.data_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'new_pipeline/'];
new_out_folder = [results_folder,'tle/'];
if ~exist(new_out_folder,'dir'), mkdir(new_out_folder); end

pwfile = locations.pwfile;
login_name = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));

%% Load patient list
ptT = readtable([data_folder,'master_pt_list.xlsx']);

%% Define left and right temporal elecs
letters = {'LA', 'LB', 'LC'};
numRange = 1:12;

% Initialize the cell array
left = cell(length(letters), length(numRange));

% Populate the cell array
for i = 1:length(letters)
    for j = 1:length(numRange)
        left{i, j} = [letters{i}, num2str(numRange(j))];
    end
end

letters = {'RA', 'RB', 'RC'};
numRange = 1:12;

% Initialize the cell array
right = cell(length(letters), length(numRange));

% Populate the cell array
for i = 1:length(letters)
    for j = 1:length(numRange)
        right{i, j} = [letters{i}, num2str(numRange(j))];
    end
end

%% Initialize table
variableNames = {'name', 'n_lt_stim_elecs', 'n_rt_stim_elecs','soz_lat','soz_loc'};
emptyCells = cell(0, length(variableNames));  % 0 rows, and columns equal to the number of variables

% Create the table from the cell array
T = cell2table(emptyCells, 'VariableNames', variableNames);



%% Load patients and pull in info
listing = dir([out_folder,'*.mat']);
for l = 1:length(listing)
    fname = [out_folder,listing(l).name];

    % Load the file
    out = load(fname);
    out = out.pt_out;

    % get the info
    name = out.name;
    labels = out.chLabels;
    stim_chs = out.stim_chs;

    % Get the corresponding loc and lat from master table
    row = find(strcmp(ptT.HUPID,name));
    assert(~isempty(row))
    soz_loc = ptT.SOZ_loc{row};
    soz_lat = ptT.SOZ_lat{row};
   
    % find the temporal ones
    % Flatten the 'cellArray'
    flatLeft = reshape(left', 1, []);  % Transpose before reshaping to maintain order by rows
    
    % Find matching elements that are also stim
    isMatch = ismember(labels, flatLeft) & stim_chs;
    
    % Extract matching elements
    lt_elecs = labels(isMatch);

    flatRight = reshape(right', 1, []);  % Transpose before reshaping to maintain order by rows
    
    % Find matching elements that are also stim
    isMatch = ismember(labels, flatRight) & stim_chs;
    
    % Extract matching elements
    rt_elecs = labels(isMatch);

    % Populate array
    T = [T;cell2table({name,length(lt_elecs),length(rt_elecs),soz_lat,soz_loc},...
        'VariableNames', variableNames)];

    % populate struct
    tle(l).name = name;
    tle(l).network = out.network;
    tle(l).lt_elecs = lt_elecs;
    tle(l).rt_elecs = rt_elecs;
    tle(l).stim_chs = stim_chs;
    tle(l).labels = labels;
    tle(l).soz_loc = soz_loc;
    tle(l).soz_lat = soz_lat;

end

% save
save([new_out_folder,'tle.mat'],'tle')
writetable(T,[new_out_folder,'tle_summary.csv'])