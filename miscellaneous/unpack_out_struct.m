stim = out.stim;
elecs = out.elecs;
chLabels = out.chLabels;
ana = out.ana;
wav = out.waveform;
dataName = out.name;
how_to_normalize = out.how_to_normalize;
nchs = size(chLabels,1);
clinical = out.clinical;
bipolar_labels = out.bipolar_labels;
bipolar_ch_pair = out.bipolar_ch_pair;
dataName = out.name;

if isfield(out,'A')
    A = out.A;
    ch_info = out.ch_info;
end