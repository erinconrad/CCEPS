stim = out.stim;
elecs = out.elecs;
chLabels = out.chLabels;
ana = out.ana;
wav = out.waveform;
dataName = out.name;
how_to_normalize = out.how_to_normalize;
nchs = size(chLabels,1);

if isfield(out,'A')
    A = out.A;
    ch_info = out.ch_info;
end