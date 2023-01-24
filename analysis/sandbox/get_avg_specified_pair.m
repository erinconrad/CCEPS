function waveform = get_avg_specified_pair(stim_label,response_label,labels,elecs)

stim = strcmp(labels,stim_label);
response = strcmp(labels,response_label);

waveform = elecs(stim).avg(:,response);


end