function elecs = get_waveforms(elecs,stim,chLabels)

% Should I normalize???

%% Parameters
idx_before_stim = 20;
n1_time = [16e-3 50e-3];
n2_time = [50e-3 300e-3];

n1_idx = round(n1_time*stim.fs);
n2_idx = round(n2_time*stim.fs);


% Loop over elecs
for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    n1 = zeros(size(elecs(ich).avg,2),2);
    n2 = zeros(size(elecs(ich).avg,2),2);
    
    stim_idx = elecs(ich).stim_idx;
    
    % redefine n1 and n2 relative to beginning of eeg
    temp_n1_idx = n1_idx + stim_idx;
    temp_n2_idx = n2_idx + stim_idx;
    
    % Loop over channels within this elec
    for jch = 1:size(elecs(ich).avg,2)
    
        % Get the eeg
        eeg = elecs(ich).avg(:,jch);
       
        
        % Get the baseline
        baseline = mean(eeg(1:stim_idx-idx_before_stim));
      
        
        % Get the eeg in the n1 and n2 time
        n1_eeg = eeg(temp_n1_idx(1):temp_n1_idx(2));
        n2_eeg = eeg(temp_n2_idx(1):temp_n2_idx(2));
        
        % subtract baseline
        n1_eeg_abs = abs(n1_eeg-baseline);
        n2_eeg_abs = abs(n2_eeg-baseline);
        
        % find the identity of the peaks
        [n1_peak,n1_peak_idx] = max(n1_eeg_abs);
        [n2_peak,n2_peak_idx] = max(n2_eeg_abs);
        
        
        if 0
            plot(linspace(elecs(ich).times(1),elecs(ich).times(2),length(eeg)),eeg)
            hold on
            plot([elecs(ich).times(1) (stim_idx-idx_before_stim)/stim.fs+elecs(ich).times(1)],[baseline baseline])
            plot((n1_peak_idx+ temp_n1_idx(1)-2)/stim.fs+elecs(ich).times(1),...
                eeg(n1_peak_idx+ temp_n1_idx(1)-1),'o')
            title(sprintf('Stim: %s, CCEP: %s\nN1 at %1.1f ms',...
                chLabels{ich},chLabels{jch},((n1_peak_idx + temp_n1_idx(1) -2)/stim.fs+elecs(ich).times(1))*1e3))
            pause
            hold off
        end
        %}
        %{
        plot(eeg)
        hold on
        plot([1 stim_idx - idx_before_stim],[baseline baseline]);
        plot(n1_peak_idx+ temp_n1_idx(1)-1,eeg(n1_peak_idx+temp_n1_idx(1)-1),'o')
        xt = get(gca, 'XTick');                                 
        set(gca, 'XTick', xt, 'XTickLabel', xt/stim.fs+elecs(ich).times(1))
        pause
        hold off
        %}
        
        
        
        % redefine idx relative to time after stim
        n1_peak_idx = n1_peak_idx + temp_n1_idx(1) - stim_idx;
        n2_peak_idx = n2_peak_idx + temp_n2_idx(1) - stim_idx;
        
        
        
        % store
        if jch == ich || jch == ich + 1
            n1(jch,:) = [nan nan];
            n2(jch,:) = [nan nan];
        else
            n1(jch,:) = [n1_peak,n1_peak_idx];
            n2(jch,:) = [n2_peak,n2_peak_idx];
        end
        
    end
    
    % add to struct
    elecs(ich).n1 = n1;
    elecs(ich).n2 = n2;
    
end

end

function time = convert_idx_to_time(idx,times)

    time = linspace(times(1),times(2),length(idx));

end