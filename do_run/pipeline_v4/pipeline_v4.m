%% pipeline_v4

overwrite = 0;

%% Updated pipeline to run through all patients in an csv file

locations = cceps_files;
data_folder = locations.data_folder;
results_folder = locations.results_folder;
out_folder = [results_folder,'pipeline_v4/'];

pwfile = locations.pwfile;
login_name = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;

% add paths
addpath(genpath(script_folder));
if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end


if ~exist(out_folder,'dir'), mkdir(out_folder); end

%% Load patient list
ptT = readtable([data_folder,'master_pt_list.xlsx']);

%% Parse instances with multiple files
for i = 1:height(ptT)
    % Check if the name contains a comma
    if contains(ptT.ieeg_filename{i}, ',')
        % Split the string by comma and convert to cell array
        ptT.ieeg_filename{i} = strsplit(ptT.ieeg_filename{i}, ',');
    end
end

% Loop through patients
for i = 1%:height(ptT)

    %% Decide if skipping
    fprintf('\nDoing patient %d of %d...\n',i,height(ptT));
    name = ptT.HUPID{i};

    if exist("specific_pt",'var')
        if ~strcmp(name,specific_pt)
            fprintf('\nSkipping %s as not the target patient %s\n',name,specific_pt)
            continue
        end
    end


    filenames = ptT.ieeg_filename{i};
    ignore_elecs = ptT.ignore_elecs{i};
    out_file_name =[name,'.mat'];

    if exist([out_folder,out_file_name],'file') ~= 0
        if overwrite == 0
            fprintf('Skipping %s\n',name);
            continue
        else
            fprintf('Overwriting %s\n',name);
        end
    else
        fprintf('Doing %s for the first time\n',name);
    end

    
    tic

    
    
    %% Decide number of files per patient
    if iscell(filenames)
        mult_files = 1;
        nfiles = length(filenames);
    else
        mult_files = 0;
        nfiles = 1;
    end
    
    all_out = cell(nfiles,1);

    % Loop over number of files
    for f = 1:nfiles
    
        if mult_files == 1
            filename = filenames{f};
        else
            filename = filenames;
        end
    
        % Do the file loop
        all_out{f} = filename_pipeline_v4(filename,login_name,pwfile,ignore_elecs);
    
    
    end
    
    %% if multiple files, stitch the output structures together
    if mult_files
        pt_out = stitch_outputs(all_out);
    else
        pt_out = all_out{1};
    end

    pt_out.name = name;

    %% Save the patient output file
    save([out_folder,out_file_name],'pt_out')

    %% do validation code
    validation_folder = [out_folder,'validation/',name,'/'];
    if ~exist(validation_folder,'dir'), mkdir(validation_folder); end
    random_rejections_keeps_v4(pt_out,validation_folder); % NEED TO ADD

    t = toc;
    fprintf('Finished patient %s in %1.1f seconds.\n',name,t)
end


function out = filename_pipeline_v4(filename,login_name,pwfile,ignore_elecs)

% 

%% Stimulation parameters
stim.train_duration = 30; % train duration (# stims) in seconds
stim.stim_freq = 1; % frequency (in Hz) of stimulation


%% Load ieeg file
server_count = 0;
% while loop in case of random server errors
while 1
    server_count = server_count + 1;
    if server_count > 50
        error('Too many server calls')

    end

    try session = IEEGSession(filename,login_name,pwfile);

    catch ME
        if contains(ME.message,'503') || contains(ME.message,'504') || ...
                contains(ME.message,'502') || contains(ME.message,'500')
            fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',server_count+1); 
            continue
        else
            ME
            error('Non-server error');
            
        end
        
    end

    break
end

%% Get annotations
n_layers = length(session.data.annLayer);
all_anns = {};

for l = 1:n_layers
    curr_ann_count = 0;
    while 1 % ieeg only lets you pull 250 annotations at a time
        if curr_ann_count == 0
            a=session.data.annLayer(l).getEvents(0);
        else
            a=session.data.annLayer(l).getNextEvents(a(curr_ann_count));
        end
        curr_ann_count = length(a);
        for k = 1:length(a)
            all_anns(end+1,:) = ...
                {l, a(k).start/(1e6), a(k).stop/(1e6), a(k).type, a(k).description};
        end
        if isempty(a), break; end
    end
end
aT = cell2table(all_anns,'VariableNames',{'Layer_num','Start','Stop','Type','Description'});

%% Get other info about the file
fs = session.data.sampleRate;
chLabels = session.data.channelLabels(:,1);
chLabels = remove_leading_zeros_v4(chLabels);
nchs = size(chLabels,1);
duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6);

% fill up stim info struct
stim.fs = fs;

%% Get the EEG data
% Get the start time of stim by finding the first closed relay annotation
% and looking 10 seconds before
index = startsWith(aT.Type, 'Closed relay') | startsWith(aT.Type,'Start Stimulation');
filteredStartTimes = aT.Start(index);
[minTime, idx] = min(filteredStartTimes); % Find the minimum start time from the filtered data
start_time = minTime - 10;
times = [start_time,duration]; % full
start_index = max(1,round(times(1)*fs));
end_index = round(times(2)*fs); 

% Get EEG data
values = zeros(end_index-start_index+1,nchs);
nchunks = min([80,nchs]);
maxAttempts = 100;
for i = 1:nchunks
    attempt = 1;

    % Wrap data pulling attempts in a while loop
    for ia = 1:maxAttempts
        if ia == maxAttempts
            error('Maxed out server errors');
        end
        try
            values(:,floor(nchs/nchunks*(i-1))+1:min(floor(nchs/nchunks*i),nchs)) =...
                session.data.getvalues([start_index:end_index],...
                floor(nchs/nchunks*(i-1))+1:min(floor(nchs/nchunks*i),nchs));
            
            % break out of while loop
            break
            
            catch ME
            % If server error, try again (this is because there are frequent random
            % server errors).
            if contains(ME.message,'503') || contains(ME.message,'504') || ...
                    contains(ME.message,'502') ||  contains(ME.message,'500')
                attempt = attempt + 1;
                fprintf('Failed to retrieve ieeg.org data, trying again (attempt %d)\n',attempt); 
            else
                ME
                error('Non-server error');
            end

        end
    
    end
    
end

%% delete the ieeg session
session.delete;

%% Identify stim periods
% Get stim periods based on annotations
periods = identify_stim_periods_v4(aT,chLabels,fs,times,ignore_elecs);

%% Get artifacts within periods
elecs = identify_artifacts_within_periods_v4(periods,values,stim,chLabels);

%% Say which electrodes have stim and start times
stim_elecs = {};
stim_chs = [];
stim_start_times = [];

for i = 1:length(elecs)
    if isempty(elecs(i).arts)
        continue
    end
    
    stim_elecs = [stim_elecs;chLabels{i}];
    stim_chs = [stim_chs;i];
    stim_start_times = [stim_start_times;elecs(i).arts(1)];
end

%% Do bipolar montage
[bipolar_values,bipolar_labels,bipolar_ch_pair] = bipolar_montage_v4(values,[],chLabels);

%% Perform signal averaging (of bipolar montage values)
elecs = signal_average_v4(bipolar_values,elecs,stim);

%% Identify CCEP waveforms
elecs = get_waveforms_v4(elecs,stim);

%% Aggregate info
out.filename = filename;
out.elecs = elecs;
out.other.stim = stim;
out.chLabels = chLabels;
out.bipolar_labels = bipolar_labels;
out.bipolar_ch_pair = bipolar_ch_pair;
out.other.periods = periods;
out.other.stim_elecs = stim_elecs;

%% Build a network
out = new_build_network_v4(out);

end


function stim =  identify_stim_periods_v4(aT,chLabels,fs,times,ignore_elecs)

stim(length(chLabels)) = struct();

for i = 1:size(aT,1)
    type = aT.Type{i};
    
    % See if it's a close relay
    if contains(type,'Closed relay to') || contains(type, 'Start Stimulation')
        
        if aT.Start(i) < times(1) || aT.Start(i) > times(2)
            continue
        end

        if contains(type,'Closed relay to')
        
            % find the electrodes
            C = strsplit(type);
            
            % fix for surprising text
            
            if length(C) == 6 && strcmp(C{5},'and')
                % expected order
                elec1_cell = C(end-2);
                elec2_cell = C(end);
            elseif length(C) == 8 && strcmp(C{6},'and') && ...
                    (strcmp(C{4},'L') || strcmp(C{4},'R'))
                % split up L/R and rest of electrode name
                elec1_cell = {[C{4},C{5}]};
                elec2_cell = {[C{7},C{8}]};
            elseif length(C) == 8 && strcmp(C{6},'and') && ...
                (strcmp(C{4}(1),'L') || strcmp(C{4}(1),'R')) % format is "RA" "1"
                % combine RA and number
                elec1_cell = {[C{4},C{5}]};
                elec2_cell = {[C{7},C{8}]};
            elseif length(C) == 10 && strcmp(C{7},'and') && ...
                    (strcmp(C{4},'L') || strcmp(C{4},'R'))
                % split up L/R and rest of electrode name
                elec1_cell = {[C{4},C{5},C{6}]};
                elec2_cell = {[C{8},C{9},C{10}]};
            else
                error('Surprising closed relay text');
                
            end
        elseif contains(type, 'Start Stimulation')

            C = strsplit(type);

            if strcmp(C{3},'from') && strcmp(C{5},'to')
                elec1_cell = C(4);
                elec2_cell = C(6);
            else
    
                error('surprising start stimulation text')
    
            end

        else
            error('what')
        end
        
        
        elec1 = elec1_cell{1};
        elec2 = elec2_cell{1};
        
        % index of first number in name
        elec1_num_idx = regexp(elec1,'\d*');
        elec2_num_idx = regexp(elec2,'\d*');

        if length(elec1_num_idx) > 1
            elec1_num_idx = elec1_num_idx(2);
        end

        if length(elec2_num_idx) > 1
            elec2_num_idx = elec2_num_idx(2);
        end
        
        % get name of electrode
        elec1_name = elec1(1:elec1_num_idx-1);
        elec2_name = elec2(1:elec2_num_idx-1);
        
        if contains(elec1_name,'ekg','IgnoreCase',true) || contains(elec1_name,'ecg','IgnoreCase',true)
            continue;
        end
        
        % Get number of contact
        elec1_contact = str2double(elec1(elec1_num_idx:end));
        elec2_contact = str2double(elec2(elec2_num_idx:end));
        
        % Get time
        start_time = aT.Start(i);
        
        % sanity checks
        if elec1_contact ~= elec2_contact - 1 &&  elec2_contact ~= elec1_contact - 1
            fprintf('\nExpecting lower number contact - one higher number contact, skipping\n');
            continue
        end
        
        if ~strcmp(elec1_name,elec2_name)
            fprintf('Expecting contacts to be from same electrodes!, skipping\n');
            continue
        end
        
        % Find the next open relay
        end_time = nan;
        for j = i+1:size(aT,1)
            type2 = aT.Type{j};
            if strcmp(type2,'Opened relay') || contains(type2,'Closed relay to') ...
                    || contains(type2,'Start Stimulation') || contains(type2,'De-block end')
                
                if aT.Start(j) > times(2)
                    end_time = times(2) - 0.5;
                    fprintf('\nWarning, setting end stim time to be time break\n');
                else                
                    end_time = aT.Start(j);
                end
                
                break
            end
        end
        if isnan(end_time)
            fprintf(['\nWarning: Never found subsequent open or closed relay after %s\n'...
                'will use last time as the end stim time\n'],aT.Type{i});
            end_time = times(2)-0.5; % subtract half second to deal with rounding errors
        end
        
        % Find electrode to assign the stim to - always assign it to the
        % LOWER NUMBER (could do LA10-LA9 or LA9-LA10, regardless, call it
        % LA9)
        
        if elec2_contact>elec1_contact
            stim_elec = elec1;
        else
            stim_elec = elec2;
        end

        stim_ch = find(strcmpi(stim_elec,chLabels));
        if isempty(stim_ch)
            if ~ismember(stim_elec,ignore_elecs)
                error('Cannot find stim channel')
            end
            continue;
        end
        stim(stim_ch).start_time = start_time;
        stim(stim_ch).end_time = end_time;
        stim(stim_ch).start_index = round((start_time-times(1))*fs);
        stim(stim_ch).end_index = round((end_time-times(1))*fs);
        stim(stim_ch).name = stim_elec;
        
           
    end
end


end


function elecs = identify_artifacts_within_periods_v4(periods,values,stim,chLabels)

%% Parameters
n_stds = 3;


fs = stim.fs;
train_duration = stim.train_duration;
stim_freq = stim.stim_freq;
max_off = 20e-3*fs;
min_off = 500e-3*fs;
allowable_nums = [train_duration:-1:train_duration-2];
goal_diff = stim_freq * fs;
min_agree = 3;

[elec_names,~] = return_contact_and_electrode(chLabels);

%% Fill in missing elecs
for ich = 1:length(periods)
    elecs(ich).arts = [];
end

% Loop through periods
for ich = 1:length(periods)
    if isempty(periods(ich).start_time)
        continue
    end
    
    % Get all contacts on that electrode
    curr_elec = elec_names{ich};
    all_elecs = find(strcmp(elec_names,curr_elec));
    
    elec_arts = cell(length(all_elecs),1);
    
    % Loop over all contacts on that electrode
    for j = 1:length(all_elecs)
        
        jch = all_elecs(j);
    
        eeg = values(periods(ich).start_index:periods(ich).end_index,jch);
        
        %% Switch nans to baseline value
        eeg(isnan(eeg)) = nanmedian(eeg);
        C = abs(eeg-nanmedian(eeg));
        thresh_C = n_stds*nanstd(eeg);
        above_thresh = find(C > thresh_C);

        candidate_arts = above_thresh;

        final_art_idx = find_beat_v4(candidate_arts,max_off,allowable_nums,goal_diff);
        final_arts = candidate_arts(final_art_idx);
        
        elec_arts{j} = final_arts;

        if 0
            figure
            plot(eeg)
            hold on
            %plot(candidate_arts,eeg(candidate_arts),'o','markersize',5)
            plot(final_arts,values(final_arts),'o','markersize',5)
            pause
            close(gcf)

        end
        
        
    
    end
    
    %% Now, take the mode across the artifacts on the different contacts to get final timing
    n_non_empty = sum(cell2mat(cellfun(@(x) ~isempty(x), elec_arts,'uniformoutput',false)));
    if n_non_empty == 0
        elecs(ich).arts = [];
        continue
    end
    consensus_arts = final_timing_v4(elec_arts,min_agree,max_off,min_off);
    
    
    
    
    if 0
        figure
        eeg = values(periods(ich).start_index:periods(ich).end_index,ich);
        plot(eeg)
        hold on
        %plot(candidate_arts,eeg(candidate_arts),'o','markersize',5)
        plot(consensus_arts,eeg(consensus_arts),'o')
        pause
        close(gcf)

    end
    
    % Re-define time relative to start
    consensus_arts = consensus_arts + periods(ich).start_index - 1;
    elecs(ich).arts = consensus_arts;
    
end

end

function final = final_timing_v4(elec_arts,min_agree,max_off,min_off)
% Unpack the cell array
all_arts = [];
for j = 1:length(elec_arts)
    all_arts = [all_arts;elec_arts{j}];
end
all_arts = sort(all_arts);

final = [];
idx = 1;

while 1
    curr = all_arts(idx);
    
    % find the indices of artifacts close to this one (these are the
    % agreeing artifacts)
    close_idx = find(abs(all_arts-curr) < max_off);
    
    % if there are enough in agreement
    if length(close_idx) + 1 >= min_agree
        
         % Take the median
        med = round(median([curr;all_arts(close_idx)]));
        
        % If there isn't already one close to this time
        if isempty(final)
            final = [final;med];
        else
            if abs(final(end) - med) > min_off
                final = [final;med];
            end
        end
    end
    
    % whether it's enough or not, advance to the next
    idx = close_idx(end) + 1;
    
    if idx >= length(all_arts)
        break
    end
end

end

function final_arts = find_beat_v4(arts,max_off,try_nums,goal_diff)
max_num_repeat = 31;
start = 1;
seq = nan;

for k = 1:length(try_nums)
    allowable_nums = try_nums(k);

    for a = start:length(arts)

        % candidate s (first time)
        s = arts(a);

        on_beat = a;

        % Loop through the other arts and see how many are within an allowable
        % distance
        for b = a+1:length(arts)

            new = arts(b);

            % If the two mod the goal diff aren't too far off
            if abs(mod(new-s,goal_diff)) < max_off && new-s > 100 && abs(new-s) < goal_diff*max_num_repeat

                if ~isempty(on_beat)
                    if abs(new-arts(on_beat(end))) < 100
                        continue
                    end
                end

                % Add it to the number that are on beat
                on_beat = [on_beat;b];

            end

            % break if too far apart
            if abs(new-s) > goal_diff*max_num_repeat
                break
            end

        end

        % Check how many are on beat
        if length(on_beat) >= min(allowable_nums)

            % If enough are on beat, then this is the correct sequence
            seq = on_beat;
            break

        end



        % If not enough on beat, try the next one

    end

    %if isnan(seq), error('Did not find it'); end


    if isnan(seq)
        %fprintf('Did not find it');
        continue
    else
        final_arts = seq;
        break

    end

end

if isnan(seq)
    final_arts = [];
end

end


function [out,bipolar_labels,bipolar_ch_pair] = bipolar_montage_v4(values,chs,chLabels)
    

if size(chLabels,1) ~=1
    chLabels = chLabels(:,1);
end

if isempty(chs)
    chs = 1:size(values,2);
end

% Initialize it as nans
out = nan(size(values,1),length(chs));
bipolar_labels = cell(length(chs),1);
bipolar_ch_pair = nan(length(chs),2);

for i = 1:length(chs)
    
    ch = chs(i);
    
    % Get electrode name
    label = chLabels{ch};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d','once');
    if isempty(label_num_idx), continue; end
    label_non_num = label(1:label_num_idx-1);


    % get numerical portion
    label_num = str2double(label(label_num_idx:end));

    % see if there exists one higher
    label_num_higher = label_num + 1;
    higher_label = [label_non_num,sprintf('%d',label_num_higher)];
    if sum(strcmp(chLabels,higher_label)) > 0
        higher_ch = find(strcmp(chLabels,higher_label));
        
        out(:,i) = values(:,ch)-values(:,higher_ch);
        bipolar_labels{i} = [label,'-',higher_label];
        bipolar_ch_pair(i,:) = [ch,higher_ch];
        
    end
    
end

end


function elecs = signal_average_v4(values,elecs,stim)

%% Parameters 
time_to_take = [-500e-3 800e-3];
fs = stim.fs;
idx_to_take = round(fs * time_to_take);
stim_time = [-5e-3 15e-3];
stim_indices = round(stim_time(1)*fs):round(stim_time(2)*fs);

for ich = 1:length(elecs)
    
    %fprintf('\nDoing ch %d of %d',ich,length(elecs));
    if isempty(elecs(ich).arts)
        continue;
    end
    
    % Get stim artifacts
    arts = elecs(ich).arts(:,1);

    % Get the indices to take 
    idx = [arts+idx_to_take(1),arts+idx_to_take(2)];
    
    % Initialize avg
    elecs(ich).avg = zeros(idx(1,2)-idx(1,1)+1,size(values,2));
    elecs(ich).stim_idx = -idx_to_take(1);
    elecs(ich).times = time_to_take;
    elecs(ich).all_bad = zeros(size(values,2),1);
    
    % Get stim idx
    stim_idx = elecs(ich).stim_idx;
    stim_indices = stim_indices + stim_idx - 1;
    
    % Initialize array listing number of bad trials
    elecs(ich).n_bad_trials = zeros(size(values,2),1);
    
    
    % Loop over all other channels
    for jch = 1:size(values,2)
       % fprintf('\n   Doing subchannel %d of %d',jch,size(values,2));
        
        % get those bits of eeg
        eeg_bits = zeros(length(arts),idx(1,2)-idx(1,1)+1);
        keep = ones(length(arts),1);
               
        for j = 1:size(idx,1)
            
            bit = values(idx(j,1):idx(j,2),jch);
            
            
            % skip if all nans
            if sum(~isnan(bit)) == 0
                eeg_bits(j,:) = bit;
                keep(j) = 0;
                continue
            end
            

            % Remove mean (so that DC differences don't affect calculation)
            bit = bit-mean(bit);
            
            all_idx = 1:length(bit);
            non_stim_idx = all_idx;
            non_stim_idx(ismember(non_stim_idx,stim_indices)) = [];


            % If ANY really high values outside of stim time, throw it out
            bit_no_stim = bit;
            bit_no_stim(stim_indices) = nan;
            if max(abs(bit_no_stim)) > 1e3
                keep(j) = 0;
                elecs(ich).n_bad_trials(j) = elecs(ich).n_bad_trials(j) + 1;
            end
            %}
            
            if 0
                plot(bit)
                hold on
                plot(bit_no_stim)
                plot([stim_indices(1) stim_indices(1)],ylim)
                plot([stim_indices(end) stim_indices(end)],ylim)
                plot(xlim,[1e3 1e3])
                plot(xlim,[-1e3 -1e3])
            end
            
            eeg_bits(j,:) = bit;
        end
        
        
        %% Average the eeg
        if sum(keep) == 0 % all bad!
            eeg_avg = nanmean(eeg_bits,1);
            all_bad = 1;
        else
            eeg_avg = nanmean(eeg_bits(keep == 1,:),1);
            all_bad = 0;
        end
   

        %% add to structure
        elecs(ich).avg(:,jch) = eeg_avg;
        elecs(ich).all_bad(jch) = all_bad;
    
    end
    
    
end

end

function elecs = get_waveforms_v4(elecs,stim)


%% Parameters
idx_before_stim = 30;
n1_time = [15e-3 50e-3];
loose_n1_time = [15e-3 50e-3];
n2_time = [50e-3 300e-3];
stim_time = [-5e-3 15e-3];
tight_stim_time = [-5e-3 10e-3];
stim_val_thresh = 1e3;
rel_thresh = 3;
fs = stim.fs;
max_crossings = 3;

n1_idx = floor(n1_time*fs);
loose_n1_idx = floor(loose_n1_time*fs);
n2_idx = floor(n2_time*fs);
stim_indices = floor(stim_time*fs);
tight_stim_indices = floor(tight_stim_time*fs);

% Loop over elecs
for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    n1 = zeros(size(elecs(ich).avg,2),2);
    n2 = zeros(size(elecs(ich).avg,2),2);
    
    stim_idx = elecs(ich).stim_idx;
    
    % redefine n1 and n2 relative to beginning of eeg
    temp_n1_idx = n1_idx + stim_idx - 1;
    temp_loose_n1_idx = loose_n1_idx + stim_idx - 1;
    temp_n2_idx = n2_idx + stim_idx - 1;
    temp_stim_idx = stim_indices + stim_idx - 1;
    temp_tight_stim = tight_stim_indices + stim_idx-1;
    
    
    % Loop over channels within this elec
    for jch = 1:size(elecs(ich).avg,2)
    
        % Get the eeg
        eeg = elecs(ich).avg(:,jch);
        
        % skip if all trials are bad
        if elecs(ich).all_bad(jch) == 1
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
            continue
        end
   
        % Get the baseline
        baseline = mean(eeg(1:stim_idx-idx_before_stim));
      
        % Get the eeg in the stim time
        stim_eeg = abs(eeg(temp_stim_idx(1):temp_stim_idx(2))-baseline);
        
        % Get the eeg in the n1 and n2 time
        n1_eeg = eeg(temp_n1_idx(1):temp_n1_idx(2));
        n2_eeg = eeg(temp_n2_idx(1):temp_n2_idx(2));
        loose_n1_eeg = eeg(temp_loose_n1_idx(1):temp_loose_n1_idx(2));
        
        % subtract baseline
        n1_eeg_abs = abs(n1_eeg-baseline);
        n2_eeg_abs = abs(n2_eeg-baseline);
        
        % Get sd of baseline
        baseline_sd = std(eeg(1:stim_idx-idx_before_stim));

        % convert n1_eeg_abs to z score
        n1_z_score = n1_eeg_abs/baseline_sd;
        n2_z_score = n2_eeg_abs/baseline_sd;
        %}
        
        %% find the identity of the peaks
        [pks,locs] = findpeaks(n1_z_score,'MinPeakDistance',5e-3*fs);
        [n1_peak,I] = max(pks); % find the biggest
        n1_peak_idx = round(locs(I));
        if isempty(n1_peak)
            n1_peak = 0;
            n1_peak_idx = 0; %erin edited 4/27/24 from nan for debug
        end
        
        [pks,locs] = findpeaks(n2_z_score,'MinPeakDistance',5e-3*fs);
        [n2_peak,I] = max(pks); % find the biggest
        n2_peak_idx = round(locs(I));
        if isempty(n2_peak)
            n2_peak = 0;
            n2_peak_idx = 0; %erin edited 4/27/24 from nan for debug
        end
        
        
        % redefine idx relative to time after stim
        eeg_rel_peak_idx = n1_peak_idx + temp_n1_idx(1) - 1;
        n1_peak_idx = n1_peak_idx + temp_n1_idx(1) - 1 - stim_idx - 1;
        n2_peak_idx = n2_peak_idx + temp_n2_idx(1) - 1 - stim_idx - 1;

        % store   
        n1(jch,:) = [n1_peak,n1_peak_idx];
        n2(jch,:) = [n2_peak,n2_peak_idx];
        
        if 0
            figure
            plot(eeg)
            hold on
            plot([temp_n1_idx(1) temp_n1_idx(1)],ylim)
            plot([temp_n1_idx(2) temp_n1_idx(2)],ylim)
            plot(xlim,[baseline baseline])
        end
        
        %% Do various things to reject likely artifact
        % 1:
        % If sum of abs value in stim period is above a certain threshold
        % relative to sum of abs value in n1 period, throw out n1
        if sum(stim_eeg) > rel_thresh * sum(n1_eeg_abs)
            n1(jch,:) = [nan nan];
        end
        
        % 2:
        % If anything too big in whole period, throw it out
        if max(abs(eeg(temp_stim_idx(1):temp_n2_idx(end))-nanmedian(eeg))) > 1e3
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        end

        
        % 3:
        % If the EEG signal in the N1 period crosses a line connecting its
        % first and last point more than twice, throw it out
        n_crossings = count_crossings(loose_n1_eeg,baseline);
      
        if n_crossings > max_crossings
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        end
        %}
        
        % 4:
        % If no return to "baseline" between stim and N1, throw it out
        %
        return_to_baseline_before = 0;
        signed_tight_stim_eeg = eeg(temp_tight_stim(1):temp_tight_stim(2))-baseline;
        
        if ~isnan(n1_peak_idx)
                       
            % if N1 above baseline
            if eeg(eeg_rel_peak_idx) - baseline > 0
                % Then look at max stim
                [max_stim,stim_max_idx] = max(signed_tight_stim_eeg);
                stim_height = max_stim - baseline;
                n1_height = eeg(eeg_rel_peak_idx) - baseline;
            else
                % Look at min stim
                [max_stim,stim_max_idx] = min(signed_tight_stim_eeg);
                stim_height = baseline - max_stim;
                n1_height =  baseline - eeg(eeg_rel_peak_idx);
            end
            stim_max_idx = stim_max_idx + temp_tight_stim(1) - 1;
      
            % Only invoke this rule if the height of the stim artifact
            % larger than height of n1
            if  stim_height > n1_height

                % If there's no part in between close to baseline
                bl_range = [baseline-1*baseline_sd,baseline+1*baseline_sd];

                if eeg(eeg_rel_peak_idx) - baseline > 0
                     % check if it gets below the upper baseline range
                    if any(eeg(stim_max_idx:eeg_rel_peak_idx) < bl_range(2))
                        return_to_baseline_before = 1;
                    end
                else
                    % check if it gets above the lower baseline range
                    if any(eeg(stim_max_idx:eeg_rel_peak_idx) > bl_range(1))
                        return_to_baseline_before = 1;
                    end
                end
            
            
                if 0
                    figure
                    plot(eeg)
                    hold on
                    plot(stim_max_idx,eeg(stim_max_idx),'o')
                    plot(eeg_rel_peak_idx,eeg(eeg_rel_peak_idx),'o')
                    plot(xlim,[bl_range(1) bl_range(1)])
                    plot(xlim,[bl_range(2) bl_range(2)])
                    if return_to_baseline_before
                        title('Ok')
                    else
                        title('Not ok')
                    end
                end

                if ~return_to_baseline_before
                    n1(jch,:) = [nan nan];
                    n2(jch,:) = [nan nan]; 
                end
            
            end
        
        end
        %}
       
        % 5:
        % if no return to baseline after N1 peak in a certain amount of
        % time, throw it out
        if ~isnan(n1_peak_idx)
            time_to_return_to_bl = 100e-3; % 50 ms
            idx_to_return_to_bl = eeg_rel_peak_idx+round(time_to_return_to_bl * fs);
            bl_range = [baseline-1.5*baseline_sd,baseline+1.5*baseline_sd];
            returns_to_baseline_after = 0;

            % if N1 above baseline
            if eeg(eeg_rel_peak_idx) - baseline > 0

                % check if it gets below the upper baseline range
                if any(eeg(eeg_rel_peak_idx:idx_to_return_to_bl) < bl_range(2))
                    returns_to_baseline_after = 1;
                end

            else

                % check if it gets above the lower baseline range
                if any(eeg(eeg_rel_peak_idx:idx_to_return_to_bl) > bl_range(1))
                    returns_to_baseline_after = 1;
                end

            end

            if ~returns_to_baseline_after
                n1(jch,:) = [nan nan];
                n2(jch,:) = [nan nan];
            end

            if 0
                figure
                plot(eeg)
                hold on
                plot([eeg_rel_peak_idx eeg_rel_peak_idx],ylim)
                plot([idx_to_return_to_bl...
                    idx_to_return_to_bl],ylim)
                plot(xlim,[bl_range(1) bl_range(1)])
                plot(xlim,[bl_range(2) bl_range(2)])
                if returns_to_baseline_after
                    title('Ok');
                else
                    title('Not ok');
                end
            end
        end
        
        
        
        
    end
    
    % add to struct
    elecs(ich).N1 = n1;
    elecs(ich).N2 = n2;
    
end

end

function time = convert_idx_to_time(idx,times)

    time = linspace(times(1),times(2),length(idx));

end


function out = new_build_network_v4(out)


%% Parameters
thresh_amp = 4;
wavs = {'N1','N2'};


%% Basic info
elecs = out.elecs;
chLabels = out.chLabels;
nchs = length(chLabels);
keep_chs = get_chs_to_ignore(chLabels);

% Loop over n1 and n2
for w = 1:length(wavs)

    which = wavs{w};
    A = nan(nchs,nchs);

    %% initialize rejection details
    details.thresh = thresh_amp;
    details.which = which;
    details.reject.sig_avg = nan(length(elecs),length(elecs));
    details.reject.pre_thresh = nan(length(elecs),length(elecs));
    details.reject.at_thresh = nan(length(elecs),length(elecs));
    details.reject.keep = nan(length(elecs),length(elecs));

    for ich = 1:length(elecs)

        if isempty(elecs(ich).arts), continue; end

        arr = elecs(ich).(which);

        % Add peak amplitudes to the array
        A(ich,:) = arr(:,1);


        all_bad = logical(elecs(ich).all_bad);
        details.reject.sig_avg(ich,:) = all_bad;
        details.reject.pre_thresh(ich,:) = isnan(elecs(ich).(which)(:,1)) & ~all_bad;
        details.reject.at_thresh(ich,:) = elecs(ich).(which)(:,1) < thresh_amp;
        details.reject.keep(ich,:) = elecs(ich).(which)(:,1) >= thresh_amp;

    end

    % Add details to array
    out.rejection_details(w) = details;


    %% Remove ignore chs
    stim_chs = nansum(A,2) > 0;
    response_chs = keep_chs;
    A(:,~response_chs) = nan;
    A = A'; % transverse!!
    A0 = A;

    %% Normalize
    A(A0<thresh_amp) = 0;
    
    %% Add this to array
    if w == 1
        out.stim_chs = stim_chs;
        out.response_chs = response_chs;
    end
    
    out.network(w).which = which;
    out.network(w).A = A;
    out.network(w).A0 = A0;

end


end

function random_rejections_keeps_v4(out,out_folder)

%% Parameters
pretty = 1;
n_to_plot = 25; % how many total to show
n_per_line = 5;
n_lines = 5;
n1_time = [10e-3 50e-3];
zoom_times = [-300e-3 300e-3];
zoom_factor = 2;
which_n = 1;

%% Get various path locations
locations = cceps_files; % Need to make a file pointing to you own path
pwfile = locations.pwfile;
loginname = locations.loginname;
script_folder = locations.script_folder;
results_folder = locations.results_folder;


name = out.name;
%out_folder = [results_folder,'validation/',name,'/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder)
end

%% Pick intracranial chs with bipolar signal
keep_chs = get_chs_to_ignore(out.bipolar_labels);

%% Get rejection details arrays
thresh = out.rejection_details(which_n).thresh;
which = out.rejection_details(which_n).which;

sig_avg = out.rejection_details(which_n).reject.sig_avg;
pre_thresh = out.rejection_details(which_n).reject.pre_thresh;
at_thresh = out.rejection_details(which_n).reject.at_thresh;
keep = out.rejection_details(which_n).reject.keep;


any_reject = sig_avg == 1| pre_thresh == 1 | at_thresh == 1;

% Calculate total numbers
nkeep = sum(keep(:) == 1);
nreject = sum(any_reject(:) == 1);
nunstim = sum(isnan(keep(:)));

if nunstim+nreject+nkeep ~= size(keep,1)*size(keep,1)
    error('numbers do not add up');
end

% Loop through rejection types
for j = 1:2
    if j == 1
        thing = keep;
        cat = 'New Keep';
    else
        thing = any_reject;
        cat = 'Reject Any';
    end
    
    meet_criteria = find(thing==1);
    
    % Restrict to those on keep chs
    [row,col] = ind2sub(size(keep),meet_criteria);
    meet_criteria(keep_chs(row) == false) = [];
    col(keep_chs(row) == false) = [];
    meet_criteria(keep_chs(col) == false) = [];
    
    % Initialize figure
    figure
    set(gcf,'position',[100 100 1200 1000])
    t = tiledlayout(n_lines,n_per_line,'padding','compact','tilespacing','compact');
    
 
    % Pick a random N
    to_plot = randsample(meet_criteria,min(n_to_plot,length(meet_criteria)));
    
    % Loop through these
    for i = 1:length(to_plot)
        
        ind = to_plot(i);
        
        % convert this to row and column
        [row,col] = ind2sub(size(keep),ind);
        
        % get why it was rejected
        why = nan;
        if j == 2
            if sig_avg(row,col) == 1
                why = 'averaging';
            end
            if pre_thresh(row,col) == 1
                if ~isnan(why)
                    error('what');
                end
                why = 'artifact';
            end
            if at_thresh(row,col) == 1
                if ~isnan(why)
                    error('what');
                end
                why = 'threshold';
            end
                
        end
        
        % Get the waveform
        avg = out.elecs(row).avg(:,col);
        times = out.elecs(row).times;
        eeg_times = convert_indices_to_times(1:length(avg),out.other.stim.fs,times(1));
        wav =  out.elecs(row).(which)(col,:);
        stim_idx = out.elecs(row).stim_idx;
        wav_idx = wav(2)+stim_idx+1;
        wav_time = convert_indices_to_times(wav_idx,out.other.stim.fs,times(1));
        n1_idx = floor(n1_time*out.other.stim.fs);
        temp_n1_idx = n1_idx + stim_idx - 1;
        
        
        % Plot
        nexttile
        plot(eeg_times,avg,'k','linewidth',2);
        hold on
        
        if ~isnan(wav(1))
            plot(wav_time,avg(wav_idx),'bX','markersize',15,'linewidth',4);
            if ~pretty
            text(wav_time+0.01,avg(wav_idx),sprintf('%s z-score: %1.1f',...
                which,wav(1)), 'fontsize',15)
            end
        end
        %xlim([eeg_times(1) eeg_times(end)])
        xlim([zoom_times(1) zoom_times(2)]);
        
        % Zoom in (in the y-dimension) around the maximal point in the N1
        % time period
        height = max(abs(avg(temp_n1_idx(1):temp_n1_idx(2))-median(avg)));
        if ~any(isnan(avg))
            ylim([median(avg)-zoom_factor*height,median(avg)+zoom_factor*height]);
        end
        
        
        labels = out.bipolar_labels;
        stim_label = labels{row};
        resp_label = labels{col};
        pause(0.1)
        xl = xlim;
        yl = ylim;
        if ~pretty
            text(xl(1),yl(2),sprintf('Stim: %s\nResponse: %s',stim_label,resp_label),...
                'horizontalalignment','left',...
                'verticalalignment','top','fontsize',10);
        end
        plot([0 0],ylim,'k--');
        set(gca,'fontsize',20)
        if pretty
            yticklabels([])
            %xticklabels([])
            xtl = xticklabels;
            xtlc = cellfun(@(x) sprintf('%s s',x),xtl,'uniformoutput',false);
            %xlabel('Time (s)')
            xticklabels(xtlc)
        end
        if j == 2
            title(why)
        end
    end
    
    if pretty == 0
        title(t,sprintf('%s %s z-score threshold %1.1f',cat,which,thresh));
    end
    
    % Save the figure
    if pretty
        fname = sprintf('%s_%sthresh_%d_pretty',cat,which,thresh);
    else
        fname = sprintf('%s_%sthresh_%d',cat,which,thresh);
    end
    print(gcf,[out_folder,fname],'-dpng');
    

    
end

    


end

function chLabels = remove_leading_zeros_v4(chLabels)

for ich = 1:length(chLabels)
    label = chLabels{ich};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d','once');
    if isempty(label_num_idx), continue; end

    label_non_num = label(1:label_num_idx-1);
    
    label_num = label(label_num_idx:end);
    
    % Remove leading zero
    if strcmp(label_num(1),'0')
        label_num(1) = [];
    end

    % fix for HUP266
    if length(label_num) >1 && strcmp(label_num(end-1),'0')
        label_num(end-1) = [];
    end
    
    label = [label_non_num,label_num];
    
    chLabels{ich} = label;
end

end