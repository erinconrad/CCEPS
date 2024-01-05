function elecs = rudy_filters(elecs,chLabels,fs)

% Reference variables  
stim_artifact_duration = round(10 * 1e-3 * fs); 
num_channels = size(chLabels,1);


% Finds first channel with keeps to reference for stim index, etc. 
kept_channel_found = 0;
channel_check = 1;
while kept_channel_found == 0 
    if ~isempty(elecs(channel_check).stim_idx)
        interpolation_period_start = elecs(channel_check).stim_idx - 3;
        kept_channel = channel_check; 
        kept_channel_found = 1;
    end
    channel_check = channel_check + 1;
end

% Generated replacement matrix (interpolate around stim artifact)
replacement = []; 

tracker=1;
for m=1:stim_artifact_duration
    replacement(tracker,1)=(interpolation_period_start-m);
    replacement(tracker,2) = 1 - ((m-1)/(stim_artifact_duration));
    replacement(tracker,3)=interpolation_period_start+2*stim_artifact_duration-m;
    replacement(tracker,4) = ((m-1)/(stim_artifact_duration));
    replacement(tracker,5) = interpolation_period_start+m-1;
    tracker = tracker +1;
end


% de-trend signal average
time_length = size(elecs(kept_channel).avg,1);

for ich=1:num_channels
    for jch=1:num_channels
        if size(elecs(ich).avg,1>=1)
            original_array = elecs(ich).avg(:,jch);
            final_array_detrended = detrend(original_array);
            elecs(ich).detrend_filt_avgs(:,jch) = final_array_detrended(:,1);
        end
    end
end

% Replace signal average around stim artifact with interpolated signal
for ich = 1:num_channels
    for jch = 1:num_channels
        for r=1:stim_artifact_duration
            if ~isempty(elecs(ich).detrend_filt_avgs)
                r1 = replacement(r,1);
                r2 = replacement(r,3);
                v1 = elecs(ich).detrend_filt_avgs(r1,jch);
                v2 = elecs(ich).detrend_filt_avgs(r2,jch);
                m1 = replacement(r,2);
                m2 = replacement(r,4);
                rep_id = replacement(r,5);
                elecs(ich).detrend_filt_avgs(rep_id,jch) = (v1*m1)+(v2*m2);
            end
        end
    end
end

% not sure, performing the interpolation?
for ich = 1:num_channels
    for jch = 1:num_channels
        if ~isempty(elecs(ich).detrend_filt_avgs)
            original_array = elecs(ich).detrend_filt_avgs([interpolation_period_start:(interpolation_period_start+stim_artifact_duration-1)],jch);
            smoothing(:,1) = replacement(:,5);
            mean_arr = movmean(original_array,5);
            smoothing(:,2) = mean_arr;
            n = size(original_array,1);
            for i = 1:n
                rep_idx = smoothing(i,1);
                rep_val = smoothing(i,2);
                elecs(ich).detrend_filt_avgs(rep_idx,jch) = rep_val;
                elecs(ich).detrend_filt_avgs(rep_idx,jch);
            end
        end
    end
end

for c=1:(size((elecs(kept_channel).detrend_filt_avgs),2))
    for r=1:(size((elecs(kept_channel).detrend_filt_avgs),2))
        if (size(elecs(c).detrend_filt_avgs))>=1
            orig = elecs(c).detrend_filt_avgs(:,r);
            temp_deriv = diff(orig);
            elecs(c).deriv(:,r) = temp_deriv;
        end
    end
end

end