function stim =  identify_stim_periods(event,chLabels,fs,times)

stim(length(chLabels)) = struct();

for i = 1:length(event)
    type = event(i).type;
    
    % See if it's a close relay
    if contains(type,'Closed relay to')
        
        if event(i).start < times(1) || event(i).start > times(2)
            continue
        end
        
        % find the electrodes
        C = strsplit(type);
        
        % fix for surprising text
        if length(C) == 6 && strcmp(C{5},'and')
            % expected order
            elec1 = C(end-2);
            elec2 = C(end);
        elseif length(C) == 8 && strcmp(C{6},'and') && ...
                (strcmp(C{4},'L') || strcmp(C{4},'R'))
            % split up L/R and rest of electrode name
            elec1 = {[C{4},C{5}]};
            elec2 = {[C{7},C{8}]};
        elseif length(C) == 10 && strcmp(C{7},'and') && ...
                (strcmp(C{4},'L') || strcmp(C{4},'R'))
            % split up L/R and rest of electrode name
            elec1 = {[C{4},C{5},C{6}]};
            elec2 = {[C{8},C{9},C{10}]};
        else
            error('Surprising closed relay text');
            
        end
        
        
        
        elec1 = elec1{1};
        elec2 = elec2{1};
        
        % index of first number in name
        elec1_num_idx = regexp(elec1,'\d*');
        elec2_num_idx = regexp(elec1,'\d*');
        
        % get name of electrode
        elec1_name = elec1(1:elec1_num_idx-1);
        elec2_name = elec2(1:elec2_num_idx-1);
        
        if contains(elec1_name,'ekg','IgnoreCase',true) || contains(elec1_name,'ecg','IgnoreCase',true)
            continue;
        end
        
        % Get number of contact
        elec1_contact = str2num(elec1(elec1_num_idx:end));
        elec2_contact = str2num(elec2(elec2_num_idx:end));
        
        % Get time
        start_time = event(i).start;
        
        % sanity checks
        if elec1_contact ~= elec2_contact - 1
            error('Expecting lower number contact - one higher number contact');
        end
        
        if ~strcmp(elec1_name,elec2_name)
            fprintf('Expecting contacts to be from same electrodes!, skipping\n');
            continue
        end
        
        % Find the next open relay
        end_time = nan;
        for j = i+1:length(event)
            type = event(j).type;
            if strcmp(type,'Opened relay') || contains(type,'Closed relay to')
                
                if event(j).start > times(2)
                    end_time = times(2) - 0.5;
                    fprintf('\nWarning, setting end stim time to be time break\n');
                else                
                    end_time = event(j).start;
                end
                
                break
            end
        end
        if isnan(end_time)
            fprintf(['\nWarning: Never found subsequent open or closed relay after %s\n'...
                'will use last time as the end stim time\n'],event(i).type);
            end_time = times(2)-0.5; % subtract half second to deal with rounding errors
        end
        
        % Find electrode to assign the stim to
        stim_ch = find(strcmp(elec1,chLabels));
        if isempty(stim_ch)
            error('Cannot find stim channel')
        end
        stim(stim_ch).start_time = start_time;
        stim(stim_ch).end_time = end_time;
        stim(stim_ch).start_index = round((start_time-times(1))*fs);
        stim(stim_ch).end_index = round((end_time-times(1))*fs);
        stim(stim_ch).name = elec1;
        
            
        
    end
end


end