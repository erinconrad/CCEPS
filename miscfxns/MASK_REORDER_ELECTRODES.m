function out = MASK_REORDER_ELECTRODES(out,mask_or_index)

% INPUTS:
% out: CCEPs output struct, containing data for N electrodes
% mask_or_index: Nx1 vector corresponding to electrodes, either logical vector to mask
% out electrodes or indices to reorder electrodes
%
% OUTPUTS:
% out: CCEPs output struct, only containing data from electrodes with a
% value of true or 1 in mask_or_index; or, ordered according to mask_or_index

if isfield(out,'waveform') % this applies to CCEPs output struct
    out.chLabels = out.chLabels(mask_or_index);
    out.bipolar_labels = out.bipolar_labels(mask_or_index);
    out.bipolar_ch_pair = out.bipolar_ch_pair(mask_or_index,:);
    out.A = out.A(mask_or_index,mask_or_index);
    out.periods = out.periods(mask_or_index);
    out.elecs = out.elecs(mask_or_index);
    for j = 1:length(out.elecs)
        if ~isempty(out.elecs(j).avg)
            out.elecs(j).avg = out.elecs(j).avg(:,mask_or_index);
            out.elecs(j).N1 = out.elecs(j).N1(mask_or_index,:);
            out.elecs(j).N2 = out.elecs(j).N2(mask_or_index,:);
        end
    end
elseif isfield(out,'locs') % this applies to electrode coordinates struct
    out.elec_names = out.elec_names(mask_or_index);
    out.locs = out.locs(mask_or_index,:);
end
    