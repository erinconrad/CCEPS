function [stim_elecs,stim_chs,stim_start_times] = return_stim_elecs_and_start_times(chLabels,elecs)

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

end