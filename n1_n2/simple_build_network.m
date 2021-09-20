function [A,ch_info]= simple_build_network(out,waveform)

% INPUTS:
% out: results structure for a patient
% waveform: 'N1' or 'N2'
%
% OUTPUTS:
% A: CCEPs network for desired waveform, with threshold applied
% ch_info: info struct about A

%% unpack
elecs = out.elecs;
stim = out.stim;
if ~isfield(out,'bad')
    bad = [];
else
    bad = out.bad;
end
chLabels = out.chLabels;
nchs = length(chLabels);

thresh_amp = 4;

keep_chs = get_chs_to_ignore(chLabels);

chs = 1:nchs;

A = nan(nchs,nchs);

%% initialize rejection details
details.thresh = thresh_amp;
details.which = waveform;
details.reject.sig_avg = nan(length(elecs),length(elecs));
details.reject.pre_thresh = nan(length(elecs),length(elecs));
details.reject.at_thresh = nan(length(elecs),length(elecs));
details.reject.keep = nan(length(elecs),length(elecs));

for ich = 1:length(elecs)
 
    if isempty(elecs(ich).arts), continue; end
    
    arr = elecs(ich).(waveform);
    
    % Add peak amplitudes to the array
    A(ich,:) = arr(:,1);
    
    all_nans = (sum(~isnan(elecs(ich).avg),1) == 0)';
    %all_nans = logical(elecs(ich).all_bad); % erin made this update
    details.reject.sig_avg(ich,:) = all_nans;
    details.reject.pre_thresh(ich,:) = isnan(elecs(ich).(waveform)(:,1)) & ~all_nans;
    details.reject.at_thresh(ich,:) = elecs(ich).(waveform)(:,1) < thresh_amp;
    details.reject.keep(ich,:) = elecs(ich).(waveform)(:,1) >= thresh_amp;
end




%% Remove ignore chs
%{
response_chs = chs;
stim_chs = chs(nansum(A,2)>0);
A = A(stim_chs,keep_chs)';
response_chs = response_chs(keep_chs);
A0 = A;
%}
stim_chs = nansum(A,2) > 0;
response_chs = keep_chs;
A(:,~response_chs) = nan;
A = A';
A0 = A;
ch_info.dimensions = {'response','stim'};

%% Normalize
A(A0<thresh_amp) = nan;
