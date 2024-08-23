function stim =  identify_stim_periods_v2(aT,chLabels,fs,times,ignore_elecs)

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

        if length(elec1_num_idx) > 1
            elec2_num_idx = elec2_num_idx(2);
        end
        
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
        
        % Find electrode to assign the stim to
        stim_ch = find(strcmpi(elec1,chLabels));
        if isempty(stim_ch)
            if ~ismember(elec1,ignore_elecs)
                error('Cannot find stim channel')
            end
            continue;
        end
        stim(stim_ch).start_time = start_time;
        stim(stim_ch).end_time = end_time;
        stim(stim_ch).start_index = round((start_time-times(1))*fs);
        stim(stim_ch).end_index = round((end_time-times(1))*fs);
        stim(stim_ch).name = elec1;
        
           
    end
end


end