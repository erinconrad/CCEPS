function values = do_filters(values,fs)

%% Notch filter
f = designfilt('bandstopiir','FilterOrder',2, ...
   'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
   'DesignMethod','butter','SampleRate',fs);
%fvtool(f)
for i = 1:size(values,2)
   values(isnan(values)) = 0;
   values(:,i) = filtfilt(f,values(:,i));   
end

%
%% High pass filter
f = designfilt('highpassiir','FilterOrder',4, ...
   'PassbandFrequency',0.5,'PassbandRipple',0.2, ...
   'SampleRate',fs);
%figure
for i = 1:size(values,2)
   % plot(values(:,i))
    %hold on
    values(:,i) = filtfilt(f,values(:,i));  
   % plot(values(:,i))
   % pause
   % hold off
end
%}

%% Common average reference
%values = values - mean(values,2);


end