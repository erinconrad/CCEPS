%{ 
Synaptic plasticity in 1Hz stimulation
%}
%Load 'out' structure from ref_withsweeps

%% Define signal filter parameters (30Hz LPF, 4th order butterworth)
fs=out.other.stim.fs;
order=4;
nyq=fs/2;
cutoff=30; %LFP at 30Hz
cutoff_norm=cutoff/nyq;
[b,a]=butter(order,cutoff_norm,'low');

%% Initialize basic variables
nchans = size(out.elecs,2);
real_trodes=[];
for i = 1:length(out.elecs)
if ~isempty(out.elecs(i).avg)
real_trodes=[real_trodes;i];
end
end
nsamples = size(out.elecs(real_trodes(1)).raw_sweeps,1);
tidx=linspace(-500,800,nsamples);

%% Define response windows of interest
N1win = [15,50]; %ms
N2win = [30,250];%ms
N1tix = find(tidx>N1win(1)&tidx<N1win(2)); %N1 
N2tix = find(tidx>N2win(1)&tidx<N2win(2)); %N2

%% Define peri-stim interval to reject
art_win = [-10,10]; %ms
art_tix = find(tidx>art_win(1)&tidx<art_win(2));

%% Define output structures
ccep_sweeps_processed = cell(nchans,nchans); %processed sweeps

%% Iterate stimulation channels, process raw sweeps
for i = 1:length(real_trodes)
    disp(i)

    %Define stimulation electrode
    stim_trode=real_trodes(i);
    
    for j = 1:nchans

        %Define response electrode
        resp_trode=j;

        %Analyze trends in N1/N2 RMS across sweeps
        if stim_trode ~= resp_trode

            %Collect raw sweep waveforms 
            % sweeps_raw appears to be nsamples x nresponse x nsweeps
            sweeps_raw=squeeze(out.elecs(stim_trode).raw_sweeps(:,resp_trode,:)); % this is what I need to make!!!!
    
            %Process raw sweeps
            sweeps_processed = nan(size(sweeps_raw));
            sweeps_processed_znorm = nan(size(sweeps_raw));
    
            for s_i = 1:size(sweeps_raw,2)
                %Indiviudal sweep waveform
                x=sweeps_raw(:,s_i);

                %Remove stim artifact
                x(art_tix)=0;

                %Apply LPF at 30Hz
                x_filt=filtfilt(b,a,x);

                %Detrend signal
                x_filt_detrend=zeros(length(x_filt),1);
                x_filt_detrend(1:art_tix(1))=detrend(x_filt(1:art_tix(1)));
                x_filt_detrend(art_tix(end):end)=detrend(x_filt(art_tix(end):end));

                %Baseline subtraction
                baseline=nanmean(x_filt_detrend(1:art_tix(1)));
                x_filt_detrend_basenorm=zeros(size(x_filt_detrend));
                x_filt_detrend_basenorm(1:art_tix(1))=x_filt_detrend(1:art_tix(1))-baseline;
                x_filt_detrend_basenorm(art_tix(end):end)=x_filt_detrend(art_tix(end):end)-baseline;

                %Store
                sweeps_processed(:,s_i)=x_filt_detrend_basenorm;
                sweeps_processed_znorm(:,s_i)=zscore(x_filt_detrend_basenorm);
            end
    
            %Store processed sweeps
            ccep_sweeps_processed{stim_trode,resp_trode} = sweeps_processed; %processed sweep
        end
    end
end


%% Detect monotonic trends of N1 and N2 across stim trials
N1_trends = [];
N2_trends = [];
idx=1;

for i = 1:length(real_trodes)
    stim_trode = real_trodes(i);
    for j = 1:nchans
        resp_trode = j;
        if ~ismember(resp_trode,out.bipolar_ch_pair(stim_trode,:))
            x = ccep_sweeps_processed{stim_trode,resp_trode};
            if ~isempty(x)
                N1_rms = rms(x(N1tix(1):N1tix(end),:),1)';
                N2_rms = rms(x(N2tix(1):N2tix(end),:),1)';
                N1_trends(idx,1:2)=[stim_trode,resp_trode];
                [N1_trends(idx,3),N1_trends(idx,4)]=corr([1:length(N1_rms)]',N1_rms,'type','spearman','rows','complete');
                N2_trends(idx,1:2)=[stim_trode,resp_trode];
                [N2_trends(idx,3),N2_trends(idx,4)]=corr([1:length(N2_rms)]',N2_rms,'type','spearman','rows','complete');
                idx=idx+1;
            end
        end
    end 
end