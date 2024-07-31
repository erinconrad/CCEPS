% Filters Signal (interpolation, 60 hz noise filter, generates derivative matrix for rejection) 
function out = chop_filtering(out)


% Reference variables  
stim_artifact_duration = 24; 
num_channels = size(out.chLabels,1);

% Finds first channel with keeps to reference for stim index, etc. 
kept_channel_found = 0;
channel_check = 1;
while kept_channel_found == 0 
    if ~isempty(out.elecs(channel_check).stim_idx)
        interpolation_period_start = out.elecs(channel_check).stim_idx - 3;
        kept_channel = channel_check; 
        kept_channel_found = 1;
    end
    channel_check = channel_check + 1;
end

% Generated replacement matrix 
out.replacement = []; 

tracker=1;
for m=1:stim_artifact_duration
    out.replacement(tracker,1)=(interpolation_period_start-m);
    out.replacement(tracker,2) = 1 - ((m-1)/(stim_artifact_duration));
    out.replacement(tracker,3)=interpolation_period_start+2*stim_artifact_duration-m;
    out.replacement(tracker,4) = ((m-1)/(stim_artifact_duration));
    out.replacement(tracker,5) = interpolation_period_start+m-1;
    tracker = tracker +1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time_length = size(out.elecs(kept_channel).avg,1);

for ich=1:num_channels
    for jch=1:num_channels
        if size(out.elecs(ich).avg,1>=1)
            original_array = out.elecs(ich).avg(:,jch);
            final_array_detrended = detrend(original_array);
            out.elecs(ich).detrend_filt_avgs(:,jch) = final_array_detrended(:,1);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATING REPLACED SIGNAL
for ich = 1:num_channels
    for jch = 1:num_channels
        for r=1:stim_artifact_duration
            if ~isempty(out.elecs(ich).detrend_filt_avgs)
                r1 = out.replacement(r,1);
                r2 = out.replacement(r,3);
                v1 = out.elecs(ich).detrend_filt_avgs(r1,jch);
                v2 = out.elecs(ich).detrend_filt_avgs(r2,jch);
                m1 = out.replacement(r,2);
                m2 = out.replacement(r,4);
                rep_id = out.replacement(r,5);
                out.elecs(ich).detrend_filt_avgs(rep_id,jch) = (v1*m1)+(v2*m2);
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ich = 1:num_channels
    for jch = 1:num_channels
        if ~isempty(out.elecs(ich).detrend_filt_avgs)
            original_array = out.elecs(ich).detrend_filt_avgs([interpolation_period_start:(interpolation_period_start+stim_artifact_duration-1)],jch);
            smoothing(:,1) = out.replacement(:,5);
            mean_arr = movmean(original_array,5);
            smoothing(:,2) = mean_arr;
            n = size(original_array,1);
            for i = 1:n
                rep_idx = smoothing(i,1);
                rep_val = smoothing(i,2);
                out.elecs(ich).detrend_filt_avgs(rep_idx,jch) = rep_val;
                out.elecs(ich).detrend_filt_avgs(rep_idx,jch);
            end
        end
    end
end

%%% SMOOTHING PART (can all be commented out) 
% https://www.mathworks.com/help/signal/ref/filtfilt.html

% num_rows = size(out.chLabels,1);
% num_columns = size(out.chLabels,1);
% 
% smoothing_start = out.replacement(1,1)
% smoothing_finish = smoothing_start + stim_artifact_duration + 10
% 
% for k=114:118
%     row = k
%     for m=1:num_channels
%         column = m;
%         if (size(out.elecs(k).detrend_filt_avgs,2))==num_channels && ~isnan(out.elecs(k).detrend_filt_avgs(1,m))
%             original_array = out.elecs(k).detrend_filt_avgs(:,m);
%             d1 = designfilt('bandstopiir','FilterOrder',6, 'HalfPowerFrequency1',57,'HalfPowerFrequency2',63,'DesignMethod','butter','SampleRate',out.other.stim.fs);
%             y = filtfilt(d1,original_array);
%             %y
%             %plot(original_array,'r');
%             %hold on
%             mean_arr = movmean(original_array,3);
%             %plot(mean_arr,'black')
% 
%             n = size(original_array,1);
%             for i=1:n
%                 subtracted_array(i,1) = original_array(i,1) - mean_arr(i,1);
%             end
%             %figure
%             %plot(subtracted_array)
% 
%             for j=1:n
%                 final_array(j,1) = original_array(j,1) - subtracted_array(j,1);
%             end
%             %figure
%             %plot(final_array,'b')
% 
%             original_array_detrended = detrend(original_array,1);
%             final_array_detrended = detrend(final_array,1);
% 
%             for w = smoothing_start:smoothing_finish 
%                 original_array_detrended(w,1) = final_array_detrended(w,1);
%             end
% 
%             out.elecs(k).detrend_filt_avgs(:,m) = y;
%         end
%     end
% end
%%

for c=1:(size((out.elecs(kept_channel).detrend_filt_avgs),2))
    for r=1:(size((out.elecs(kept_channel).detrend_filt_avgs),2))
        if (size(out.elecs(c).detrend_filt_avgs))>=1
            orig = out.elecs(c).detrend_filt_avgs(:,r);
            temp_deriv = diff(orig);
            out.elecs(c).deriv(:,r) = temp_deriv;
        end
    end
end
end